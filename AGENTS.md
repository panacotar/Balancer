# AGENTS.md

Guidance for AI agents working on Balancer.

## Read first

Before changing code, read:

1. [`docs/modernization.md`](docs/modernization.md) for the supported runtime,
   setup, validation, compatibility decisions, and deferred work.
2. The relevant controller, model, policy, service, view, and tests for the
   behavior being changed.
3. [`.github/workflows/ci.yml`](.github/workflows/ci.yml) before changing build
   or test commands.

The root [`README.md`](README.md) is intentionally the original short project
overview plus a link to the modernization guide. Put current operational
documentation in `docs/modernization.md`; do not replace the README with a new
setup guide.

## Project purpose and scope

Balancer is a Rails demo for social-impact crowdfunding. Founders create
projects and campaigns; registered users make Stripe test-mode pledges.

Important scope decisions:

- This is a demo. It must never accept live Stripe credentials or represent
  demo pledges as real investments.
- The supported data model is a fresh demo database. Legacy production-data
  migration is outside the current scope unless a task explicitly adds it.
- Preserve the existing interface and behavior unless the task requests a
  redesign.
- Bootstrap 4 replacement and deployment/hosting modernization are separate
  follow-ups. The old Docker/Fly configuration is not supported for this stack.

## Supported stack

- Ruby 3.4.11 and Bundler 4.0.23
- Rails 8.1.4
- PostgreSQL 15 or newer; CI uses PostgreSQL 17
- Node 24.22.1 and npm 11.19.1
- esbuild for JavaScript
- Dart Sass plus Autoprefixer for CSS
- Sprockets for serving built assets
- Minitest, Capybara, Selenium, WebMock, Brakeman, and Bundler Audit

Use the pinned versions in `.ruby-version`, `.node-version`, `Gemfile.lock`,
and `package.json`. npm is the only JavaScript package manager; do not add a
Yarn lockfile or restore Webpacker.

## Repository map

```text
app/controllers/       Request handling and Pundit authorization
app/models/            Active Record domain rules and associations
app/policies/          Pundit ownership and visibility rules
app/services/          Demo seeds and Stripe checkout fulfillment
app/views/             ERB views using the existing Bootstrap 4 design
app/javascript/        esbuild entry point and browser components
app/assets/stylesheets Existing SCSS, compiled by scripts/build-css.mjs
scripts/               JavaScript and CSS build scripts
db/                    Schema, migrations, and repeatable demo seeds
test/                  Minitest controller/model/policy/system coverage
docs/modernization.md  Canonical setup, validation, and upgrade notes
```

## Local setup and commands

Start PostgreSQL and select the pinned Ruby and Node versions, then:

```sh
gem install bundler -v 4.0.23
cp .env.example .env
bin/setup
bin/dev
```

`bin/setup` installs gems and npm packages, builds both asset bundles, prepares
the database, and seeds a new development database. `bin/dev` runs Rails and
the JavaScript/CSS watchers through Foreman.

If the repository's isolated local PostgreSQL cluster already exists:

```sh
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
export PGHOST=127.0.0.1 PGPORT=55439
pg_ctl -D "$PWD/tmp/pgdata" -l "$PWD/tmp/postgres.log" \
  -o "-p 55439 -h 127.0.0.1 -k $PWD/tmp/pgsocket" start
```

Keep the PostgreSQL variables in every terminal that runs Rails or tests. See
`docs/modernization.md` for troubleshooting and provider configuration.

## Architecture and invariants

### Authentication and authorization

- Devise authentication is required by default in `ApplicationController`.
- Public actions must opt out explicitly with `skip_before_action`.
- Pundit verification runs after controller actions. Authorize records before
  persisting them or calling an external provider.
- Project and campaign changes require ownership. Orders and payment details
  are visible only to the order's user.
- Add or update policy tests when authorization behavior changes.

### Stripe demo checkout

The checkout flow spans:

- `OrdersController#create`: validates the pledge, reserves campaign capacity
  with a pending order, and creates the hosted Checkout Session.
- `PaymentsController#new`: retrieves and validates the exact hosted session.
- `StripeWebhooksController#create`: verifies the signature and accepts only
  test-mode events.
- `StripeCheckout::Fulfill`: validates session identity and amount, locks the
  order and campaign, and creates the shareholder exactly once.

Preserve these invariants:

- Accept only Stripe test keys and `livemode == false`.
- Never create a shareholder from a success/cancel redirect.
- Validate session ID, order metadata, client reference, amount, currency,
  mode, payment status, and completion status.
- Pending orders reserve campaign capacity through
  `Campaign#available_pledge`.
- Recheck confirmed capacity while holding the campaign lock at fulfillment.
- Keep fulfillment idempotent. `paid` and `failed` are terminal order states,
  and an order has at most one shareholder.
- A deterministic over-cap result should return webhook success rather than
  trigger endless Stripe retries.
- Stub Stripe calls in automated tests; tests must not require credentials or
  network access.

### Money and campaign capacity

- Order money is stored in integer cents through MoneyRails.
- Shareholder amounts and percentages are decimals.
- Parse pledge input with `Order.parse_pledge`; do not convert money through
  `Float`.
- `Campaign#remaining_pledge` is confirmed capacity.
- `Campaign#available_pledge` subtracts pending reservations.
- Funding percentages count confirmed shareholders only.
- Use database locks for capacity decisions that race with checkout creation or
  webhook fulfillment.

### Images and external services

- Development uses local Active Storage unless `CLOUDINARY_URL` is present.
- Test storage is isolated under `tmp/storage`.
- Production is configured for Cloudinary, but deployment remains deferred.
- Use `attachment_image_tag` so local and Cloudinary attachments both render.
- Keep credentials in environment variables or Rails credentials. Never commit
  secrets, provider payloads containing secrets, or a real `.env` file.
- Tests disable external network connections with WebMock.

### Seeds and database changes

- `DemoSeeds.run` must remain repeatable and must not delete existing records.
- Seed images come from repository assets; do not add runtime downloads.
- Seeded accounts use random passwords.
- Test database preparation must not seed demo records.
- Change the database through migrations and regenerate `db/schema.rb`.
- Add foreign keys and unique indexes for invariants that must survive
  concurrency.

## Frontend and assets

- `app/javascript/application.js` is the esbuild entry point.
- `app/assets/stylesheets/application.sass.scss` is the Sass entry point.
- Build with `npm run build` and `npm run build:css`.
- Built files under `app/assets/builds/` are generated and ignored except for
  `.keep`; do not commit them.
- Preserve Rails UJS and Turbolinks lifecycle handling. Initialize browser
  components on `turbolinks:load` and tear down stateful components before the
  page is cached.
- Existing Bootstrap 4 Sass can emit the documented `abs-percent` warning. It
  is non-blocking if the CSS build completes.
- Keep the current visual design unless a task explicitly changes it.

## Testing and validation

Use helpers in `test/test_helper.rb` instead of fixtures. Keep external calls
stubbed and add regression coverage near the changed behavior.

Fast feedback:

```sh
bin/rails test test/models/campaign_test.rb
bin/rails test test/controllers/orders_controller_test.rb
```

Full behavior validation:

```sh
bin/rails zeitwerk:check
bin/rails test
bin/rails test:system
```

Dependency, security, and production-build validation:

```sh
bundle exec bundler-audit check --update
bundle exec brakeman --no-pager
npm audit --audit-level=low
RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
git diff --check
```

CI runs Rails tests, Chrome system tests, eager loading, production asset
compilation, and all three security audits. Match CI commands when changing
tooling. System tests require Chrome.

## Change discipline

- Inspect the current working tree before editing; preserve unrelated changes.
- Prefer focused changes with tests over broad modernization.
- Update `docs/modernization.md` when setup, runtime, checkout, storage, CI, or
  deferred-work facts change.
- Do not claim a provider integration was verified live when it was mocked.
- Do not claim legacy or intermediate Rails upgrade paths passed unless they
  were actually run.
- Run the narrowest relevant tests during development and the full affected
  suite before handing work off.
