# AGENTS.md

Guidance for AI agents working on Balancer.

## Scope

Balancer is a Rails demo for social-impact crowdfunding. Founders create projects and campaigns. Registered users make Stripe test-mode pledges.

- Preserve the existing Bootstrap 4 interface, database schema, and seed content unless the task requires a change.
- Keep `README.md` as the short project overview. Do not turn it into a new guide, and keep the Le Wagon attribution.
- This is a demo. Do not accept live Stripe credentials or describe pledges as real investments.
- Do not rewrite git history or force-push.

## Stack

Use the versions pinned in `.ruby-version`, `.node-version`, `Gemfile.lock`, and `package.json`.

- Ruby 3.4.11, Rails 8.1, Bundler 4.1
- Node 24 and npm. Do not add a Yarn lockfile or restore Webpacker.
- PostgreSQL
- esbuild and Dart Sass, served by Sprockets
- Devise for authentication and Pundit for authorization

JavaScript builds from `app/javascript/packs/application.js` through `scripts/build.mjs`. CSS builds through `scripts/build-css.mjs`.

## Commands

```sh
bin/setup
bin/dev
bin/rails db:seed
bin/rails test
```

`bin/setup` installs gems and npm packages, builds assets, and prepares the database. `bin/dev` runs Rails plus the asset watchers. On macOS, port 5000 is often AirPlay, so confirm the port Puma prints.

If `bin/rails` cannot find gems, unset `BUNDLE_PATH` and run it with `RBENV_VERSION=3.4.11`.

## Environment

Copy `.env.example` to `.env`. Do not commit `.env`.

- Stripe keys are test keys. Local webhook setup is in `doc/stripe.md`. `STRIPE_WEBHOOK_SECRET` is required for `POST /stripe/webhook`.
- Set `DOMAIN` in production only. A blank `DOMAIN` must not become the URL host. `ApplicationController#default_url_options` ignores it outside production.
- `SENTRY_DSN` is optional.

## Domain rules

- Devise authentication is required unless an action calls `skip_before_action :authenticate_user!`.
- Authorize with Pundit before saving or calling Stripe. Project and campaign changes require ownership. An order is visible only to its user.
- A pledge is a positive whole number no larger than the campaign's available amount. Pending checkouts reserve that amount for 24 hours under a campaign row lock. Fulfillment checks the goal again and refunds a payment that no longer fits.
- Do not `return` inside `with_lock` or a transaction. Rails rolls the transaction back.
- `investment_goal` is a whole number greater than 0. `equity` is a whole number from 1 to 100.
- `Project#target` is the audience description, not a number.

## Photos

Active Storage uses the local disk in development and production. Files live in `storage/` and are not committed. Render attachments with `image_tag`, not Cloudinary helpers. Include a Stripe product image only when `DOMAIN` is set.

## Tests

Minitest covers controllers, models, and policies. WebMock blocks network calls except localhost. Keep new authorization and payment behavior covered by a test.
