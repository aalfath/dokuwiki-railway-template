#!/bin/bash
# Railway wrapper for the official DokuWiki image.
#  1. Listen on $PORT (default 8080).
#  2. Prepare the /storage volume the way the upstream entrypoint does.
#  3. On the first boot only, run DokuWiki's installer headlessly with the
#     admin account from the environment, so the public install.php is never
#     open to whoever reaches the site first.
#  4. Hand over to the upstream entrypoint (Apache in the foreground).
set -euo pipefail

PORT="${PORT:-8080}"
case "$PORT" in (*[!0-9]*|'') echo "railway-start: PORT must be a number" >&2; exit 1;; esac
echo "Listen ${PORT}" > /etc/apache2/ports.conf

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
run_as_www /dokuwiki-storagesetup.sh >/dev/null

if ! run_as_www php /railway-install.php; then
  echo "railway-start: first-boot install failed; not starting DokuWiki so install.php is never exposed." >&2
  exit 1
fi

exec /dokuwiki-entrypoint.sh
