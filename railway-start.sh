#!/bin/bash
# Railway wrapper for the official DokuWiki image.
#  1. Listen on $PORT (default 8080).
#  2. Prepare the /storage volume the way the upstream entrypoint does.
#  3. On the first boot only, run DokuWiki's installer headlessly with the
#     admin account from the environment, so the public install.php is never
#     open to whoever reaches the site first.
#  4. Start Apache in the foreground, as the upstream entrypoint does.
set -euo pipefail

PORT="${PORT:-8080}"
case "$PORT" in (*[!0-9]*|'') echo "railway-start: PORT must be a number" >&2; exit 1;; esac
echo "Listen ${PORT}" > /etc/apache2/ports.conf

# PHP's Apache image runs mpm_prefork only. Railway's builder can bring back
# the base image's mpm_event links, and Apache then refuses to start with
# "AH00534: More than one MPM loaded", so keep prefork and drop the others.
if [ -w /etc/apache2/mods-enabled ]; then
  rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.*
  [ -e /etc/apache2/mods-enabled/mpm_prefork.load ] || a2enmod -q mpm_prefork >/dev/null
fi

export ADMIN_USER="${ADMIN_USER:-admin}"
export ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
export ADMIN_FULLNAME="${ADMIN_FULLNAME:-Administrator}"
export WIKI_TITLE="${WIKI_TITLE:-DokuWiki}"
export WIKI_ACL_POLICY="${WIKI_ACL_POLICY:-1}"
export WIKI_ALLOW_REGISTER="${WIKI_ALLOW_REGISTER:-0}"
export WIKI_LICENSE="${WIKI_LICENSE:-cc-by-sa}"
export WIKI_LANG="${WIKI_LANG:-en}"
export WIKI_TRUSTED_PROXIES="${WIKI_TRUSTED_PROXIES:-}"

run_as_www() {
  if [ "$(id -u)" -eq 0 ]; then
    setpriv --reuid=33 --regid=33 --init-groups "$@"
  else
    "$@"
  fi
}

if [ "$(id -u)" -eq 0 ]; then
  mkdir -p /storage
  chown -R www-data:www-data /storage
fi
# Same steps as /dokuwiki-entrypoint.sh, without its `set -x` trace (it can hit
# Railway's log rate limit and hide the lines that matter).
echo "railway-start: preparing /storage (uid $(id -u))"
run_as_www /dokuwiki-storagesetup.sh >/dev/null 2>&1 || { echo "railway-start: storage setup failed" >&2; run_as_www bash -x /dokuwiki-storagesetup.sh; exit 1; }

if ! run_as_www php /railway-install.php; then
  echo "railway-start: first-boot install failed; not starting DokuWiki so install.php is never exposed." >&2
  exit 1
fi

echo "railway-start: starting Apache on port ${PORT}"
exec docker-php-entrypoint apache2-foreground
