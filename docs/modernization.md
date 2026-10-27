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

Without Cloudinary configuration, development uploads use local `storage/`. Demo seeds use bundled photos and randomly generated account passwords; register your own account to explore. Seeds do not delete existing domain records and are not intended as a legacy-data migration. Test database preparation skips demo seeding.

### Demo catalogue

`db/demo_campaigns.yml` restores the eleven campaign names from the historical
`db/seeds.rb` at commit `2782db3`, including Briiv, Atelier Riforma, Hitch, AMX,
and QuenchSea. Matching project stories and founder profiles are fictional.
Campaign descriptions are at most 80 characters, and pitches identify the
content as illustrative. Historical product names do not imply current brand
affiliation, product availability, certification, or health benefits.

The catalogue has eleven founders (`demo1@example.test` through
`demo11@example.test`) and three fictional backers. Every new account receives
its own random password; existing passwords are preserved. Eleven themed photos
are bundled under `db/seeds/photos/`, with photographer credits, source URLs,
and license information in `db/seeds/photos/SOURCES.md`. Seeding never downloads
photos. Active Storage still uses the configured local or Cloudinary service.

On a fresh database, campaigns have varied goals, equity, active dates, and
15–80% sample funding. Three backers split each campaign's sample funding
50/30/20. These are synthetic paid demo receipts with matching shareholders,
`demo-seed-` references, and no Stripe session or provider calls. They do not
represent actual payments or investments.

Rerun `bin/rails db:seed` to refresh the six known `Community project N` /
`Community campaign N` placeholders in place and add the five remaining entries.
The refresh preserves their IDs, existing orders and pledges, custom photos,
and unrelated records. Only the original `demo-project.jpg` with matching bus
image bytes is replaced. Campaigns with existing financial records retain their
goal and equity. New or refreshed placeholders receive dates relative to that
run; ordinary reruns preserve those dates, even after the campaign has ended.

Backing is repeatable and capped against capacity under campaign locks, including
pending reservations. Existing sample receipts are never rewritten; available
capacity can reduce or prevent sample backing on an existing campaign. Seed runs
are serialized with a PostgreSQL advisory lock. Conflicting campaign names,
ambiguous seed records, or occupied demo account identities raise
`DemoSeeds::Conflict` and roll back the refresh instead of adopting unrelated
records. Production updates do not automatically reseed; initialization does.

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
| `CLOUDINARY_URL` | Optional Cloudinary credentials; development and production otherwise use local Active Storage |
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

## VPS production deployment

Docker Compose runs Rails and PostgreSQL 17 as separate containers on one VPS.
Uploads and PostgreSQL use separate named volumes. The existing SillyStories
Caddy container routes both sites; **do not start a second public proxy**.
The hostname is runtime configuration, not part of the image. Fly/Kamal are not
maintained deployment targets.

The target server has 4 GB RAM, two ARM vCPUs and Ubuntu. The current defaults
limit Rails to 768 MiB (one Puma process, three threads) and PostgreSQL to 512 MiB.
SillyStories currently budgets 384 MiB for Node, 768 MiB for MongoDB, and 256 MiB
for shared Caddy: combined container ceilings are 2.625 GiB, excluding host and
maintenance overhead. These are limits, not reservations or load-test results.
Build off-server, stagger backups, and measure `docker stats --no-stream`,
`free -h`, `df -h` and CPU after deployment. Investigate OOM restarts, sustained
swapping, or repeatedly less than 500 MiB available memory before adding load.

### Prepare the server and configuration

Use a supported Ubuntu release with current Docker Engine and the Compose v2+
plugin, Python 3.9+, Bash, OpenSSL, curl and Git. Confirm SSH key access and the
OS version (`cat /etc/os-release`), architecture (`uname -m`, expected aarch64),
free memory/disk and existing Caddy configuration before cutover. Keep OS security
updates enabled. Restrict SSH to your administrator IP/VPN using your actual SSH
port. Public inbound TCP 80/443 belongs to Caddy; application/database ports and
the Docker API stay private. Apply provider firewall rules as well as host rules:
[Docker-published ports can bypass UFW](https://docs.docker.com/engine/network/packet-filtering-firewalls/).
Docker access is root-equivalent; do not mount its socket in application containers.

On the VPS, clone this repository (examples use `~/Balancer`), then:

```sh
cd ~/Balancer
scripts/setup-production.sh
```

Edit `.env.production` with your image tag, public hostname, SMTP host/username,
and a provider-verified `MAIL_FROM`. SMTP uses authenticated STARTTLS on port 587
by default and verifies certificates. Put the SMTP password into
`deploy/secrets/smtp_password` using a private editor. No local mail server is
needed. Configure the provider's SPF/DKIM records and send a real password-reset
email before advertising account recovery.

Setup generates random Rails and database secrets **only when absent**. Optional
Stripe, Cloudinary and Sentry secret files start empty; populate them to enable
those services. `secret_key_base` must remain at least 64 characters. The Rails
app sees only its restricted PostgreSQL role; the admin secret is DB-only.
`RuntimeSecrets` reads these files before Rails configuration. Direct environment
variables remain usable outside Compose. Never use `SECRET_KEY_BASE_DUMMY` at runtime.

The host secrets directory is mode 0700. Individual files are readable inside
non-root containers (0644) because local Compose bind mounts preserve host UID
and permissions; host protection depends on that private parent directory.
Compose secrets are not encrypted storage. Keep private backups of secrets
separately and never commit them, print their contents, or include them in image
build contexts. Editing database password files alone does not rotate existing
PostgreSQL credentials. Preserve them across updates.

### Build and initialize

On an ARM64 development computer with Docker, or an ARM64 CI builder:

```sh
scripts/build-image.sh
# Prints dist/balancer-COMMIT.tar.gz. Transfer it privately over SSH:
scp dist/balancer-COMMIT.tar.gz DEPLOY_USER@YOUR_VPS:~/
```

The default tag is the committed Git SHA and requires a clean checkout. An
explicit tag is supported for local validation. An x86 builder needs Buildx
ARM64 emulation or a remote ARM64 builder. Node/npm and build dependencies are
excluded from the runtime image. CI also builds and exercises the image natively
on `ubuntu-24.04-arm`; an unrun workflow is not evidence of a passing build.

On the VPS:

```sh
docker image load --input ~/balancer-COMMIT.tar.gz
# Set APP_IMAGE=balancer:COMMIT in ~/Balancer/.env.production, then:
cd ~/Balancer
scripts/deploy-production.sh init
scripts/production.sh ps
```

Initialization creates the edge network, starts PostgreSQL, refuses an existing
application schema, migrates the empty database and seeds the demo once. It does
not migrate legacy data. The PostgreSQL initialization script creates a login
role with no superuser, role-creation or database-creation privileges, owning only
Balancer's database. Existing data and uploads survive web container replacement.
The image entrypoint does not run migrations automatically.

### Connect the existing Caddy and domain

The supplied override assumes the existing SillyStories production Compose file,
`public`/`frontend` networks, `app:3000` upstream, and `DOMAIN`/`ACME_EMAIL`
environment match its repository configuration. Compare them with the live stack
first. The combined Caddyfile preserves that route and its 8 KB body limit, adding
Balancer with an 8 MB body limit and a distinct `balancer-web:3000` upstream.
It shares only an edge network with Balancer; the two databases remain isolated.

In the `organicdarius.com` DNS zone add an A record named `balancer` pointing to
`YOUR_VPS_IPV4`. Add AAAA only when your VPS IPv6 and firewall work. Remove stale
records. Use DNS-only mode (no additional CDN proxy); a future CDN needs a review
of trusted proxy/IP handling. Restrictive CAA records must allow Caddy's issuer.
Caddy handles certificate issuance, renewal, and HTTP-to-HTTPS redirects.

Run on the VPS, substituting the actual absolute checkout paths:

```sh
export BALANCER_ROOT="$HOME/Balancer"
export EDGE_NETWORK=balancer-edge
cd ~/SillyStories
# Review merged configuration; only Caddy gains a network/config mount.
docker compose --env-file .env.production -f compose.production.yaml \
  -f "$BALANCER_ROOT/deploy/caddy.compose.yaml" config --quiet
# Validate before replacing the existing proxy; preserves certificate volumes.
docker compose --env-file .env.production -f compose.production.yaml \
  -f "$BALANCER_ROOT/deploy/caddy.compose.yaml" run --rm --no-deps \
  --entrypoint caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
docker compose --env-file .env.production -f compose.production.yaml \
  -f "$BALANCER_ROOT/deploy/caddy.compose.yaml" up -d --no-deps caddy
curl --fail https://balancer.organicdarius.com/healthcheck
curl --fail https://silly-stories.organicdarius.com/healthz
```

The one-time Caddy recreation briefly interrupts both sites because its admin API
is disabled. Keep using this override whenever recreating/updating SillyStories'
Caddy; its ordinary app update helper does not recreate Caddy. Without the
override a Caddy recreation removes Balancer routing. Revert to the original
Caddy definition to undo integration without changing either database.
The combined Caddyfile contains the Balancer hostname; update that site block too
if choosing a different hostname. The image itself remains reusable.

### Updates and rollback

Build and transfer the next version, load its archive, set `APP_IMAGE` to the new
tag in `.env.production`, and run:

```sh
~/Balancer/scripts/deploy-production.sh update
```

The helper verifies a locally loaded ARM64 image, backs up the current database
and uploads, records the previous release, stops only Balancer, runs migrations,
and starts/checks the replacement. It verifies public HTTPS on updates. A failed
build leaves the old app untouched; a failed migration leaves Balancer stopped
for inspection. A public-check failure leaves the replacement running for
inspection. These releases have a short maintenance interruption.

For an application-only rollback, first check that database migrations remain
compatible with the previous image, then:

```sh
~/Balancer/scripts/rollback-production.sh --schema-compatible
```

This does not reverse migrations or restore data. Set `APP_IMAGE` in the env file
to match `.release` after rollback. Keep the previous image available; avoid
unattended image/volume pruning. To recover incompatible data changes, use a
verified backup and an isolated recovery stack rather than automatically deleting
production storage. A rollback can lose newer writes if database restoration is
required, so determine the recovery point explicitly.

### Backups and recovery

```sh
~/Balancer/scripts/backup-production.sh
```

The helper stops Balancer if running, dumps PostgreSQL and archives uploads while
writes remain stopped, creates checksums and a versioned recovery archive, then
restarts the app even if backup fails. It leaves an already-stopped app stopped.
Completed archives live in private `backups/`, with seven-day local retention.
They contain personal data and are not encrypted. Copy recovery sets off-server
through an encrypted channel to protected storage; backups on this VPS cannot
survive loss of the VPS. **An automated offsite destination is not configured**:
that provider decision was deferred. Keep old copies until offsite retention is
established. Preserve Rails/DB/provider secrets separately for disaster recovery.

For daily backups, edit the deployment user and absolute paths in the service,
then install it on the VPS:

```sh
sudo cp ~/Balancer/deploy/balancer-backup.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now balancer-backup.timer
systemctl list-timers balancer-backup.timer
```

The timer uses 04:15 UTC with up to five minutes jitter. Stagger from SillyStories'
backup. Check failed units, backup timestamps, disk space and logs regularly;
there is no external alerting service configured.

Test recovery in a **separate checkout** with its own secret directory, env file,
`COMPOSE_PROJECT_NAME=balancer-recovery` and `EDGE_NETWORK=balancer-recovery-edge`.
Use the exact image tag recorded in the backup (inspect with
`tar -xOf BACKUP.tar.gz image.txt`) and preserve the original Rails secret if
existing signed links/sessions must survive. Do not attach recovery to Caddy.
Run setup to generate DB credentials for the new empty PostgreSQL instance, then:

```sh
/path/to/recovery/Balancer/scripts/restore-production.sh /absolute/path/BACKUP.tar.gz
```

Restore validates the archive/checksums and exact image, refuses populated schemas
or upload volumes, restores under the application DB role, starts Rails and
checks internal health. If recovery fails, the web app stays stopped. Compare
record counts and downloaded image bytes before routing traffic. Database
passwords in a new isolated stack can differ; the dump excludes role passwords.
Maintenance helpers use `.production-operation.lock`; remove a stale lock only
after confirming its recorded process is gone and no maintenance is active.

### Public-hosting behavior and validation

Production enforces the configured hostname and HTTPS, host-only secure cookies,
and HSTS for this hostname only. Caddy overwrites untrusted forwarded headers;
Rails has no public port. `/healthcheck` checks the DB and returns 503 on failure;
its internal probe is exempt from host/HTTPS redirects. Container health status
alone does not cause Docker to restart an unhealthy process.

Login: 10 attempts/3 minutes; signup: 5/hour; password recovery: 5/15 minutes;
authenticated direct-upload creation: 20/hour, all per IP. Multipart project/campaign
photo writes share a separate 20/hour limit per account. Counters are in memory
and reset on restart; keep one Puma process. Password-recovery responses do not
reveal whether an account exists. Photos are JPEG/PNG/WebP, at most 5 MiB. CSP
permits the existing inline styles, Google Fonts, Unsplash and Cloudinary images
while restricting scripts to this app. Stripe remains strictly test-only.

Before public handoff, verify HTTP redirect and certificate validity, both apps'
health endpoints, signup/login, SMTP reset delivery, image upload/download after
web recreation, and a backup recovery drill. Configure Stripe's test webhook at
`https://balancer.organicdarius.com/stripe/webhook` and test checkout only after
supplying test keys/signing secret. Never claim live SMTP/Stripe/Cloudinary
verification based on mocked tests.

Local deployment tests (no Docker needed):

```sh
python3 -m unittest discover -s test/deployment -p '*_test.py' -v
```

For an ARM64 image and a responsive Docker daemon, run
`scripts/test-container.sh balancer:TAG`. It creates and deletes only an isolated
test stack, verifies production security/persistence, and restores its DB/uploads.
It validates the shared Caddy configuration without touching the real proxy.

## Deferred frontend work

Bootstrap 4, Popper 1, Turbolinks, Slick 1, and amCharts 4 remain for visual
compatibility. A clean dependency audit does not mean these libraries are
actively maintained. Their replacement is a separate frontend follow-up.

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

No production database, hosting account, live deployment, DNS, or live payment configuration was touched during modernization. The current Compose setup is documented above; live provider verification remains an operator step.

## Validation on 2026-10-21

- A separate clean source copy passed `bin/setup` using pinned Ruby/Node, no node_modules or built assets, and a new isolated PostgreSQL database. Its six seeded projects/campaigns and stored image bytes were verified; repeat seeding produced no duplicate records.
- Regression suite: 33 tests, 214 assertions, no failures/errors/skips, with CI eager loading enabled. This includes the updated Cloudinary adapter with its external upload call stubbed and signed synthetic Stripe webhook events.
- Headless Chrome: 2 system tests, 18 assertions, no failures/errors/skips, including a complete browser image upload. No severe browser console errors were observed.
- Production assets compiled without provider credentials. All 12 local CSS image/font references resolved. Production eager loading, `/healthcheck`, `/`, and `/campaigns` passed against the isolated demo database.
- Frozen Bundler install, npm immutable installs, Bundler Audit, npm audit, Brakeman, and `git diff --check` passed. Dependency audits reported no vulnerabilities; Brakeman reported no warnings.
- Live Stripe and Cloudinary accounts and the GitHub-hosted CI runner were not exercised. Their credentials and provider deployment remain future setup steps.


## VPS implementation validation on 2026-10-23

- Ruby 3.4.11/Bundler 4.0.23 and Node 24.22.1/npm 11.19.1 were used for validation.
- Rails regression suite: 50 tests, 315 assertions; Chrome system suite: 2 tests,
  18 assertions, all passed. Eight deployment helper tests also passed, covering
  lock exclusion, secret preservation, backup failure recovery, migration
  failure, empty-database guards and unsafe/corrupt archive rejection.
- Production assets and eager loading passed. An isolated PostgreSQL database
  supported production-mode checks for host authorization, HTTPS redirects,
  secure cookies, HSTS, CSP, DB readiness, URL/mail configuration and disk storage.
- Bundler Audit, npm audit and Brakeman passed after updating only the vulnerable
  transitive `crass` dependency from 1.0.7 to 1.0.8. The existing Bootstrap Sass
  `abs-percent` warning remains non-blocking.
- Production Compose configuration and resource/isolation assertions passed.
  The Caddy override merge preserves SillyStories networks and certificate
  volumes, and the combined Caddyfile passed native Caddy validation.
- After restarting the stuck local Docker Desktop service, the ARM64 image built
  and passed the full container lifecycle/recovery smoke test: non-root and
  read-only operation, restricted PostgreSQL role, HTTPS/host/cookie/CSP checks,
  persistent image bytes across recreation, consistent backup/restore, and
  refusal to overwrite an existing database. The harness also pins its Compose
  project/network so inherited environment variables cannot target other stacks.
- Container inspection caught and fixed Bundler's deployment-path default and
  inherited Docker ignore rules that re-included nested test storage. Runtime
  trees, local tunnel tooling and host gem caches are now excluded and tested.
- The local image is `balancer:validation`; its transferable archive is
  `dist/balancer-validation.tar.gz` (about 130 MiB). A light-use Docker snapshot
  showed about 212 MiB for Rails and 22 MiB for PostgreSQL, excluding host overhead
  and filesystem cache. This is not a load benchmark or a VPS measurement.
- The native ARM64 CI job is configured for the same image/lifecycle checks; the
  GitHub-hosted workflow itself has not been run in this task.
- No VPS, DNS, live SMTP/Stripe/Cloudinary integration or offsite backup target
  was changed or verified live.

## Demo catalogue validation on 2026-10-25

- Ruby 3.4.11/Bundler 4.0.23 and Node 24.22.1/npm 11.19.1 were used for validation.
- Rails regression suite: 57 tests, 865 assertions; Chrome system suite: 2 tests,
  18 assertions, all passed. Seed coverage includes in-place placeholder refresh,
  repeatability, photo/password preservation, financial record preservation,
  capacity with pending reservations, cent precision, and conflict rollback.
- Eager loading, production assets, eight deployment helper tests, Bundler Audit,
  npm audit, Brakeman, and `git diff --check` passed. The documented Bootstrap
  Sass deprecation warning remains non-blocking.
- ARM64 image `balancer:seed-refresh` passed the container lifecycle and backup
  recovery smoke test, including all eleven photo byte comparisons and all 33
  matching synthetic demo orders/shareholders after recreation and restore.
- The local `Balancer_development` database was refreshed: eleven campaigns,
  twelve projects (including one preserved unrelated project), and 33 sample
  receipts. The six original seed project/campaign IDs and existing unrelated
  domain records were verified unchanged.
- Browser inspection confirmed the existing nine-card catalogue layout, varied
  funding progress, and all eleven project pages returning HTTP 200 with loaded
  photos and demo copy. No VPS or live payment/provider configuration was changed.
