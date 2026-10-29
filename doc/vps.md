# Deploy to the VPS

Balancer runs as two containers on the same VPS as SillyStories. SillyStories'
Caddy is the only public listener.

```text
Internet → Caddy (HTTPS) → Balancer (Rails) → Postgres
```

Postgres is on an internal network and publishes no ports. Uploaded photos live
in the `balancer_uploads` volume. Rebuilding the app image leaves the database
and photos in place.

Commands below run on the VPS unless marked otherwise. Examples use
`~/Balancer`. Docker names the volumes `balancer_postgres_data` and
`balancer_uploads`, separate from the checkout.

## 1. Prepare the VPS

You need SSH, Git, OpenSSL, curl, and
[Docker Engine with Compose](https://docs.docker.com/engine/install/ubuntu/).
The deployment user must be able to run Docker. Build on the VPS so the image
matches its CPU. An ARM64 VPS is supported. Host Ruby and Node.js are not required.

Before the site is public:

- Use SSH keys. After confirming key login works, disable password and root login.
- Keep unattended OS security updates enabled. Docker access is root-equivalent.
- Add a 2 GB swap file. Image builds compile assets and can briefly need about
  1 GB. That step is not covered by the container memory caps, so build while
  the VPS is quiet.
- Keep the VPS provider's firewall even if you also use UFW. Ports published by
  Docker can bypass UFW. See
  [Docker's firewall notes](https://docs.docker.com/engine/network/packet-filtering-firewalls/).

| Service | TCP port | Allowed source |
| --- | --- | --- |
| SSH | 22 | Your administrator IP or VPN |
| HTTP | 80 | Public |
| HTTPS | 443 | Public |

Do not publish the app port, the database port, or the Docker API.

## 2. DNS

In the `organicdarius.com` zone:

| Type | Name | Value |
| --- | --- | --- |
| A | `balancer` | The VPS IPv4 address |
| AAAA | `balancer` | The VPS IPv6 address, only if it is configured and reachable |

Use DNS-only mode if the DNS host offers a proxy. Caddy obtains the certificate
once port 80 on this VPS answers for `balancer.organicdarius.com`.

## 3. Configure the checkout

Clone the repository, check out the branch you want to run, then:

```sh
cd ~/Balancer
scripts/setup-production.sh
```

Edit `.env.production` (mode 600, not committed):

- Leave `DOMAIN=balancer.organicdarius.com`, without `https://` or a path.
- Set `STRIPE_PUBLISHABLE_KEY` and `STRIPE_SECRET_KEY` to Stripe **test** keys
  (`pk_test_` and `sk_test_`). The app refuses to boot if either key is a live key.
- Leave `STRIPE_WEBHOOK_SECRET` until the webhook exists (step 6).
- Password reset needs SMTP. Set `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`,
  `SMTP_PASSWORD`, and `MAIL_FROM` together, or leave `SMTP_ADDRESS` empty.
- `SENTRY_DSN` is optional.

Setup generates `SECRET_KEY_BASE` and `BALANCER_DATABASE_PASSWORD`. It does not
overwrite an existing `.env.production`. The database role is `balancer`. It is
a Postgres superuser because it owns this private database, and it is reachable
only from the Balancer app container.

Always use `scripts/production.sh` for production Compose commands.

## 4. Point Caddy at Balancer

SillyStories already listens on ports 80 and 443. From the SillyStories checkout,
pull the Caddyfile that includes `balancer.organicdarius.com`, then:

```sh
docker network create balancer-edge
scripts/production.sh up -d caddy
```

`scripts/setup-production.sh` in either checkout creates `balancer-edge`. Caddy
joins that network and proxies `balancer.organicdarius.com` to the Balancer
container. If Balancer is down, only that hostname returns an error.

## 5. Build and start

Run the image build while the VPS is quiet:

```sh
scripts/update-production.sh
scripts/production.sh run --rm web bin/rails db:seed
```

The update script builds `balancer:<git sha>`, starts Postgres and the app, and
migrates the database. Seed once, on an empty database. Seeding again inserts
another copy of the sample projects.

Check the containers and the public URL:

```sh
scripts/production.sh ps
curl -I http://balancer.organicdarius.com
curl --fail https://balancer.organicdarius.com/healthcheck
```

`curl -I` should show a redirect to HTTPS. Only Caddy publishes host ports.
`docker ps` should not show `5432` or Balancer's port `3000`.

## 6. Stripe webhook

In the Stripe dashboard, test mode, add an endpoint:

```text
https://balancer.organicdarius.com/stripe/webhook
```

Put the signing secret in `STRIPE_WEBHOOK_SECRET` in `.env.production`, then
restart the app:

```sh
scripts/production.sh up -d --no-build --wait web
```

Local webhook setup is in [stripe.md](stripe.md). Pledges are Stripe
test-mode payments, not real investments.

## 7. Update and roll back

On your computer, run the test suite and push. On the VPS:

```sh
cd ~/Balancer
scripts/update-production.sh
```

That pulls fast-forward commits, backs up the current database and photos if
the stack is already running, builds a new image, and replaces the containers.
Keep the previous `balancer:<sha>` image until the new one is checked. The
previous tag is written to `.previous-release`.

```sh
scripts/rollback-production.sh
```

Rollback starts the previous image. It does not restore the database. Use the
backup from that update if a migration has to be undone.

## 8. Backup and restore

```sh
scripts/backup-production.sh
```

Each run writes `backups/<timestamp>/database.dump` and `uploads.tar.gz`, and
keeps the 14 newest directories. Copy those directories off the VPS. An offsite
destination is not configured yet.

A daily timer is in [deploy/balancer-backup.service](../deploy/balancer-backup.service)
and [deploy/balancer-backup.timer](../deploy/balancer-backup.timer). Edit `User` and both
paths to match the deployment account and checkout, then:

```sh
sudo cp deploy/balancer-backup.service deploy/balancer-backup.timer /etc/systemd/system/
sudo systemctl enable --now balancer-backup.timer
```

Or add a cron line for the deployment user:

```cron
15 3 * * * cd /home/deploy/Balancer && ./scripts/backup-production.sh >> backups/backup.log 2>&1
```

Restore stops the site and replaces the database and photos:

```sh
scripts/restore-production.sh backups/20260101T031500Z --yes
```

Do not delete the Docker volumes with `docker compose down -v` or volume
pruning. That removes the only on-server copy of the database and photos.

## 9. Memory

Steady use for Balancer is about 250–450 MB: Rails often 150–300 MB, Postgres
often 50–120 MB. The app is capped at 512 MB and Postgres at 384 MB, so a spike
stops that container instead of the whole VPS. Together with SillyStories
(Caddy 256 MB, Node 384 MB, MongoDB 768 MB) the caps are about 2.3 GB. Real use
stays near 1.1–1.6 GB plus the operating system, which fits a 4 GB VPS.

Keep one Puma process. Do not add worker processes or a Redis container. The
app cache is in memory.

## 10. Follow-up

The content security policy is report-only. After the site is up, check the
browser console on the home page, a project page, and a pledge page. When those
are clean, turn off report-only mode in
`config/initializers/content_security_policy.rb`.
