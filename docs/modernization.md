# Balancer modernization

## Result

The app targets Ruby 3.4.11, Rails 8.1.4, Node 24.22.1 and npm 11.19.1. Bundler 4.0.23 is locked. Linux x86_64 and ARM64 platforms are included in the gem lockfile. This phase uses a fresh demo database, preserves the frontend design, and supports only Stripe test payments.


Balancer is a demo: founders create projects and campaigns, and visitors explore them and make Stripe test-mode pledges. No real investments or payments are supported.

## Requirements

- Ruby **3.4.11** and Bundler **4.0.23** (`.ruby-version`, `Gemfile.lock`)
- Node.js **24.22.1**, npm **11.19.1** (`.node-version`, `package.json`)
- PostgreSQL **15 or newer**; CI uses PostgreSQL 17
- Chrome for browser tests

Rails is **8.1.4**. JavaScript uses esbuild; SCSS uses Dart Sass and Autoprefixer. Sprockets serves the resulting assets. npm is the only JavaScript package manager.

## Local setup

Start PostgreSQL, select the pinned Ruby/Node versions with your version manager, then:

```sh
gem install bundler -v 4.0.23
cp .env.example .env
bin/setup         # new development databases receive demo seeds
bin/rails db:seed  # safely rerun demo seeding when needed
```

The default databases are `Balancer_development` and `Balancer_test`. Standard PostgreSQL variables (`PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`) configure connections; Rails also supports `DATABASE_URL`. Use a separate test database when setting a URL.

Without Cloudinary configuration, development uploads use local `storage/`. Demo seeds use a bundled image and randomly generated account passwords; register your own account to explore. Seeds do not delete existing records and are not intended as a legacy-data migration. Test database preparation skips demo seeding.

For automatic asset rebuilding:

```sh
gem install foreman
bin/dev
```

Alternatively, run `npm run build`, `npm run build:css`, and `bin/rails server`. Visit http://localhost:3000.

## Local testing troubleshooting

### Homebrew PostgreSQL tools

On macOS, `pg_ctl` from the client-only `libpq` package cannot start a database server: it has no `postgres` executable beside it. Select the installed PostgreSQL server's tools instead. For PostgreSQL 15:

```sh
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
```

If reusing the isolated PostgreSQL 15 cluster created during this modernization, run these commands from the repository root:

```sh
export PGHOST=127.0.0.1 PGPORT=55439
pg_ctl -D "$PWD/tmp/pgdata" -l "$PWD/tmp/postgres.log" \
  -o "-p 55439 -h 127.0.0.1 -k $PWD/tmp/pgsocket" start
bin/setup
bin/rails server
```

This cluster is local test infrastructure under the ignored `tmp/` directory. A fresh checkout needs its own running PostgreSQL server. Keep `PGHOST` and `PGPORT` set in each terminal used to run Rails or its tests.

Select Node 24.22.1 before setup; the default Node on the development machine was version 26. The Node runtime downloaded under `/tmp` during validation is temporary, so use a version manager for ongoing development.

### Sass `abs-percent` warning

Bootstrap 4's bundled RFS styles trigger a Dart Sass deprecation warning about `abs()` with percentage units. If the output ends with `Built application.css and fonts` and `Setup complete`, setup succeeded. This warning does not block testing; it remains part of the deferred Bootstrap replacement.

## Stripe demo checkout

Browsing and account features work without Stripe keys. To enable checkout, configure these in `.env`:

| Variable | Purpose |
| --- | --- |
| `STRIPE_SECRET_KEY` | Stripe test secret (`sk_test_…` or `rk_test_…`) |
| `STRIPE_PUBLISHABLE_KEY` | Matching test publishable key (`pk_test_…`) |
| `STRIPE_WEBHOOK_SECRET` | Signing secret for the webhook endpoint |
| `DOMAIN` | Optional host and port for absolute checkout URLs; defaults to the request host |

Live API keys are rejected. Use a Stripe test account/sandbox and test cards only.

With the Stripe CLI authenticated to your **test account**, forward events locally:

```sh
stripe listen --events checkout.session.completed --forward-to localhost:3000/stripe/webhook
```

Copy the signing secret printed by that command into `STRIPE_WEBHOOK_SECRET` and restart Rails. Make a pledge, open hosted test checkout, and use Stripe's documented test card details. The signed webhook creates the pledge and marks its exact order paid. Refresh the order page if the event has not arrived yet. Opening success/cancel URLs never creates a pledge; repeated events never create duplicates.

Automated tests stub Stripe requests and sign synthetic webhook events. They do not need API keys or make real payments. See [Stripe test guidance](https://docs.stripe.com/testing).

## Images and error reporting

| Variable | Purpose |
| --- | --- |
| `CLOUDINARY_URL` | Optional Cloudinary credentials for development; production is configured to use Cloudinary |
| `SENTRY_DSN` | Optional Sentry reporting |

Cloudinary uploads retain their transformations. Local and test uploads render through Active Storage. Keep credentials in environment variables or encrypted Rails credentials, never source control. See `.env.example` for placeholders.

## Validation

```sh
bundle install
npm ci
bin/rails db:prepare
bin/rails zeitwerk:check
bin/rails test
bin/rails test:system
bundle exec bundler-audit check --update
bundle exec brakeman --no-pager
npm audit --audit-level=low
RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
```

Chrome system tests cover carousels, navigation, the pledge modal, charts, date pickers, and upload forms. Tests and production precompilation build assets automatically, using an immutable `npm ci` install.

GitHub Actions runs the checks above. Dependabot checks gems and npm weekly and workflow actions monthly.

## Remaining work before hosting

Hosting selection and deployment configuration are deferred. **The old Dockerfile and Fly configuration have not been modernized and should not be used for this stack yet.** A hosting follow-up must align the container/runtime build, database configuration, release migrations, Cloudinary, URL/mail configuration, HTTPS, and persistent services with the chosen provider.

Bootstrap 4, Popper 1, Turbolinks, Slick 1, and amCharts 4 remain for visual compatibility. A clean dependency audit does not mean these libraries are actively maintained. Their replacement is a separate frontend follow-up.

## Compatibility changes

- Webpacker Ruby 4 and JavaScript 5 were mismatched. Both are removed; esbuild bundles JavaScript and cssbundling/Dart Sass compiles the existing SCSS. Rails UJS and Turbolinks remain. Font Awesome, Flatpickr, Slick and AOS styles are built locally. Images and font URLs are fingerprinted through Sprockets.
- npm and Yarn previously resolved different Rails client versions. npm is now authoritative; both asset build tasks share one `npm ci` prerequisite. Arbitrary transitive dependencies previously added as vulnerability workarounds are removed.
- Rails defaults are 8.1. Removed APIs/configuration, Spring launchers, obsolete browser-driver tooling, the invalid `updated` resource declaration, and unused Action Cable/Redis client scaffolding are removed or corrected.
- The new migration adds modern Active Storage service/variant metadata, associates a pledge with its unique order, and changes pledge amounts/percentages to decimal columns. Existing money columns remain integer cents. Pledge input accepts positive decimal euros with no more than two fractional digits; it is converted directly to Money without float arithmetic. Half-even rounding is explicit.
- Cloudinary 2 renders transformed cloud images; development/test disk uploads use normal Active Storage URLs. Database seeding uses bundled images instead of remote image downloads and creates no accounts with a shared password.
- Campaign edits now require project ownership. Order authorization happens before persistence or Stripe calls. The old shareholder GET and POST routes redirect without creating records.
- Stripe Checkout uses `price_data`, explicit payment mode, an order reference, request idempotency, and a hosted session URL. The test-only webhook verifies signature, mode, amount, currency, session ID and order identity. Pending checkouts reserve remaining campaign capacity. Fulfillment locks the campaign and the order, and commits a pledge only when the paid amount still fits; otherwise the order fails and the webhook returns success so Stripe does not retry it. A unique order association prevents duplicates. Canceling an open or expired checkout releases its reservation. Unpaid events do not fulfill an order.

## Audit baseline and maintenance debt

Before updating, the npm lockfile audit reported 151 affected packages (7 critical, 42 high); many came from Webpacker tooling. The Ruby audit also found known advisories. Neither baseline count is an assessment of exploitability in a running deployment. The complete resolved graphs are updated rather than bypassing audit failures with ignore lists.

Bootstrap 4.6.2 is end-of-life. Popper 1, Turbolinks 5, Slick 1, and amCharts 4 remain deliberately to preserve the interface; npm emits deprecation notices for some of them and their transitive packages. AOS moves from a prerelease to the stable 2.3 line. Major frontend replacements, Turbo, and Bootstrap 5 belong in a separate follow-up. The old SCSS still uses deprecated Sass imports/functions; selected known deprecation warnings are suppressed in the build script, not compilation errors.

Only esbuild's pinned install script is allowed in npm's install-script policy. Optional Parcel watcher compilation and core-js's informational postinstall are denied; CSS watching uses Node's filesystem watcher.

## Upgrade verification limits

The original app was statically inspected and its original lockfiles audited. Ruby 2.6.6 was unavailable locally; an isolated attempt to build it failed on the current ARM64 macOS toolchain. Consequently an exact original-runtime baseline and passing runs for every intermediate Rails minor version were **not established**. The final application has been migrated against the Rails upgrade guidance and validated directly on the supported destination; this is not a claim that sequential 6.1/7.x/8.0 runtime checkpoints passed.

No production database, hosting account, deployment, DNS, or live payment configuration was touched. The Dockerfile/Fly setup remains a deployment follow-up.

## Validation on 2026-10-21

- A separate clean source copy passed `bin/setup` using pinned Ruby/Node, no node_modules or built assets, and a new isolated PostgreSQL database. Its six seeded projects/campaigns and stored image bytes were verified; repeat seeding produced no duplicate records.
- Regression suite: 33 tests, 214 assertions, no failures/errors/skips, with CI eager loading enabled. This includes the updated Cloudinary adapter with its external upload call stubbed and signed synthetic Stripe webhook events.
- Headless Chrome: 2 system tests, 18 assertions, no failures/errors/skips, including a complete browser image upload. No severe browser console errors were observed.
- Production assets compiled without provider credentials. All 12 local CSS image/font references resolved. Production eager loading, `/healthcheck`, `/`, and `/campaigns` passed against the isolated demo database.
- Frozen Bundler install, npm immutable installs, Bundler Audit, npm audit, Brakeman, and `git diff --check` passed. Dependency audits reported no vulnerabilities; Brakeman reported no warnings.
- Live Stripe and Cloudinary accounts and the GitHub-hosted CI runner were not exercised. Their credentials and provider deployment remain future setup steps.
