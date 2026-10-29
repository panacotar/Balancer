# Deploy to the VPS

Balancer is standalone: it can run its own HTTPS proxy, or share an existing
one, with no configuration naming either side.

```text
Internet → Caddy (HTTPS) → Balancer (Rails) → Postgres
```

Postgres is on an internal network and publishes no ports. Uploaded photos live
in the `balancer_uploads` volume. Rebuilding the app image leaves the database
and photos in place.

`scripts/setup-production.sh` checks whether ports 80 and 443 are already in
use on the host, every time it runs:

- **Free:** Balancer starts its own `caddy` container (Compose profile
  `caddy`) and gets a certificate for `DOMAIN` directly. This is the common
  case for a VPS dedicated to Balancer.
- **In use:** something else already owns those ports. Balancer does not
  start its own Caddy. Setup instead creates the external Docker network
  `balancer-edge` and prints a site block to add to whatever already runs
  there, so that proxy can reach `balancer-web:3000`. Balancer's own files
  never name that other proxy or project.

Re-run `scripts/setup-production.sh` any time the host's port usage changes;
it switches modes automatically.

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

Open HTTP and HTTPS regardless of which mode section 4 ends up in: either
Balancer's own Caddy uses them, or another proxy on this host already does.
Do not publish the app port, the database port, or the Docker API.

## 2. DNS

In the `example.com` zone:

| Type | Name | Value |
| --- | --- | --- |
| A | `balancer` | The VPS IPv4 address |
| AAAA | `balancer` | The VPS IPv6 address, only if it is configured and reachable |

Use DNS-only mode if the DNS host offers a proxy. Whichever Caddy ends up
serving Balancer (see section 4) obtains the certificate once port 80 on this
VPS answers for `balancer.example.com`.

## 3. Configure the checkout

Clone the repository, check out the branch you want to run, then:

```sh
cd ~/Balancer
scripts/setup-production.sh
```

Edit `.env.production` (mode 600, not committed):

- Set `DOMAIN=balancer.example.com`, without `https://` or a path. Replace `example.com` with your domain.
- Set `STRIPE_PUBLISHABLE_KEY` and `STRIPE_SECRET_KEY` to Stripe **test** keys
  (`pk_test_` and `sk_test_`). The app refuses to boot if either key is a live key.
- Set `STRIPE_WEBHOOK_SECRET` before the first start. Create the test-mode
  endpoint in the Stripe dashboard (step 6) and copy its signing secret.
  Production refuses to boot while this value is blank.
- Password reset needs SMTP. Set `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`,
  `SMTP_PASSWORD`, and `MAIL_FROM` together, or leave `SMTP_ADDRESS` empty.
  The SMTP server must support STARTTLS; delivery fails if TLS is unavailable.
- `SENTRY_DSN` is optional.
- If setup reported that ports 80/443 were free, set `ACME_EMAIL` to a real
  contact address for certificate renewal notices.

Setup generates `SECRET_KEY_BASE` and `BALANCER_DATABASE_PASSWORD`. It does not
overwrite an existing `.env.production`. The database role is `balancer`. It is
a Postgres superuser because it owns this private database, and it is reachable
only from the Balancer app container.

Always use `scripts/production.sh` for production Compose commands. It reads
`CADDY_PROFILE` from `.env.production` and starts the `caddy` service only
when setup set that to `caddy`.

## 4. Reverse proxy

Setup already decided this when it ran in step 3. Check `.env.production`:

**`CADDY_PROFILE=caddy`** — ports 80/443 were free. Balancer owns them and
runs its own Caddy container from [deploy/Caddyfile](../deploy/Caddyfile). No
further action is needed here; it starts with the rest of the stack in step 5.

**`CADDY_PROFILE=` (empty)** — something else already listens on 80/443.
Balancer stays off those ports. That proxy needs two separate changes. The
`docker network connect` command is not a place to paste the site block.

1. Join the proxy container to Balancer's network. This lasts until that
   container is recreated:

```sh
docker network connect balancer-edge <proxy-container>
```

`<proxy-container>` is the container that publishes ports 80 and 443
(`docker ps`). If Docker answers that an endpoint with that name already
exists in `balancer-edge`, the container is already connected. Leave it and
continue with step 2.

2. Add a site to the Caddyfile that container already loads. Find the file on
   the host:

```sh
docker inspect <proxy-container> --format '{{range .Mounts}}{{if eq .Destination "/etc/caddy/Caddyfile"}}{{.Source}}{{end}}{{end}}'
```

Open that path and append the block below. Leave every existing site in the
file. Use the same hostname as `DOMAIN` in `.env.production`.

```caddyfile
balancer.example.com {
	encode zstd gzip
	header -Server
	header Strict-Transport-Security "max-age=31536000"
	request_body {
		max_size 10MB
	}
	reverse_proxy balancer-web:3000 {
		header_up -Forwarded
		header_up X-Forwarded-For {remote_host}
		header_up X-Forwarded-Proto {scheme}
		header_up X-Forwarded-Host {host}
	}
}
```

3. Restart the proxy container so it reads the file again. A restart keeps
   the network connection from step 1. Recreating the container drops it, and
   step 1 has to be run again.

```sh
docker restart <proxy-container>
```

Any reverse proxy that can join `balancer-edge` and point at
`balancer-web:3000` works the same way. If Balancer is down, only its
hostname fails. The proxy's other sites stay up. Re-run
`scripts/setup-production.sh` later if port usage on the host changes; it
switches `CADDY_PROFILE` automatically.

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
curl -I http://balancer.example.com
curl --fail https://balancer.example.com/healthcheck
```

`curl -I` should show a redirect to HTTPS. Only a Caddy container (Balancer's
own, or the one already on the host) publishes ports 80/443. `docker ps`
should not show `5432` or Balancer's port `3000` published.

## 6. Stripe webhook

In the Stripe dashboard, test mode, add an endpoint:

```text
https://balancer.example.com/stripe/webhook
```

Copy the signing secret into `STRIPE_WEBHOOK_SECRET` in `.env.production`
before `scripts/update-production.sh`. The app will not boot without it.
If you change the secret later, restart the app:

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
often 50–120 MB. Add roughly 20–40 MB if Balancer runs its own Caddy (capped
at 128 MB). The app is capped at 512 MB and Postgres at 384 MB, so a spike
stops that container instead of the whole VPS. These numbers cover Balancer
only; add whatever else shares this VPS on top.

Keep one Puma process. Do not add worker processes or a Redis container. The
app cache is in memory.

## 10. Follow-up

The content security policy is report-only. After the site is up, check the
browser console on the home page, a project page, and a pledge page. When those
are clean, turn off report-only mode in
`config/initializers/content_security_policy.rb`.
