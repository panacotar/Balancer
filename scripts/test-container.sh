#!/bin/bash
# Destructive only to a newly created, disposable test project and its volumes.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
image=${1:?Usage: test-container.sh IMAGE}
test_root=$(mktemp -d /tmp/balancer-container.XXXXXX)
project="balancer-test-$$"
network="$project-edge"
# Shell environment takes precedence over --env-file. Pin the disposable project
# explicitly so cleanup can never target another exported Compose project.
export COMPOSE_PROJECT_NAME="$project" EDGE_NETWORK="$network" APP_IMAGE="$image"
export DOMAIN=balancer.example.test SMTP_ADDRESS=smtp.example.test SMTP_USERNAME=demo MAIL_FROM=demo@example.test
mkdir -p "$test_root/deploy"
cp "$ROOT/compose.production.yaml" "$ROOT/.env.production.example" "$test_root/"
cp "$ROOT/deploy/postgres-init.sh" "$test_root/deploy/"
cp -R "$ROOT/scripts" "$test_root/"
compose() { "$test_root/scripts/production.sh" "$@"; }
cleanup() {
  result=$?
  trap - EXIT
  if [ "$result" -ne 0 ]; then compose logs --tail=100 || true; fi
  compose down --volumes --remove-orphans || true
  docker network rm "$network" >/dev/null || true
  rm -rf "$test_root"
  exit "$result"
}
trap cleanup EXIT
"$test_root/scripts/setup-production.sh"
cat > "$test_root/.env.production" <<EOF
APP_IMAGE=$image
DOMAIN=balancer.example.test
SMTP_ADDRESS=smtp.example.test
SMTP_USERNAME=demo
MAIL_FROM=demo@example.test
EDGE_NETWORK=$network
COMPOSE_PROJECT_NAME=$project
EOF
[ "$(docker run --rm --entrypoint id "$image" -u)" = 1000 ]
docker run --rm --entrypoint sh "$image" -c '! command -v node && ! test -d /rails/node_modules && ! test -d /rails/vendor/bundle && ! test -e /rails/config/master.key && ! test -d /rails/deploy/secrets && ! test -e /rails/tmp/local_secret.txt && ! test -d /rails/tmp/storage && ! test -e /rails/ngrok'
"$test_root/scripts/deploy-production.sh" init
[ "$(compose exec -T --user postgres db psql -U postgres -d balancer_production -Atc \
  "SELECT rolsuper OR rolcreatedb OR rolcreaterole FROM pg_roles WHERE rolname='balancer'")" = f ]
compose exec -T web sh -c 'test ! -w /rails/app && test -w /rails/storage'
check_data() {
  compose exec -T web bin/rails runner - <<'RUBY'
abort 'missing seed records' unless [User.count, Project.count, Campaign.count, Order.count, Shareholder.count] == [14, 11, 11, 33, 33]
DemoSeeds::CATALOGUE.each do |entry|
  campaign = Campaign.find_by!(name: entry.fetch(:name))
  abort "lost upload: #{entry.fetch(:key)}" unless campaign.project.photo.download == File.binread(DemoSeeds.photo_path(entry))
  expected_funding = entry.fetch(:investment_goal).to_d * entry.fetch(:funding_percent) / 100
  abort "lost backing: #{entry.fetch(:key)}" unless campaign.shareholders.sum(:amount) == expected_funding
  campaign.orders.each do |order|
    abort 'invalid demo receipt' unless order.state == 'paid' && order.checkout_session_id.nil? &&
                                        order.campaign_sku.start_with?('demo-seed-') && order.shareholder&.amount == order.amount.to_d
  end
end
RUBY
}
check_data
compose exec -T web ruby -rnet/http -e '
  def request(host, path, ssl)
    headers = { "Host" => host }
    headers["X-Forwarded-Proto"] = "https" if ssl
    Net::HTTP.start("127.0.0.1", 3000) { |http| http.get(path, headers) }
  end
  abort "host authorization" unless request("attacker.example", "/", true).code == "403"
  abort "HTTP redirect" unless request("balancer.example.test", "/", false).code == "301"
  page = request("balancer.example.test", "/users/sign_in", true)
  abort "HTTPS page" unless page.code == "200"
  abort "CSP missing" unless page["Content-Security-Policy"].include?("script-src")
  abort "insecure cookie" unless page["Set-Cookie"].include?("secure")
  abort "HSTS missing" unless page["Strict-Transport-Security"]
'
compose up -d --no-deps --no-build --force-recreate --wait web
check_data
"$test_root/scripts/backup-production.sh"
# Exercise restore from an empty database and volume in this disposable project.
compose down --volumes
archive=$(find "$test_root/backups" -name 'balancer-*.tar.gz' -type f)
"$test_root/scripts/restore-production.sh" "$archive"
check_data
if "$test_root/scripts/restore-production.sh" "$archive"; then
  echo 'Restore unexpectedly accepted a populated database.' >&2
  exit 1
fi
check_data
docker run --rm -e DOMAIN=silly-stories.example.test -e ACME_EMAIL=demo@example.test \
  -v "$ROOT/deploy/shared.Caddyfile:/etc/caddy/Caddyfile:ro" caddy:2-alpine \
  caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
echo 'Container smoke checks passed, including persistence and backup recovery.'
