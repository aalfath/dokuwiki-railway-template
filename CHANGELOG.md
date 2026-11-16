# Changelog

## 2026-07-14c (2026-11-16)

- First release of the Railway template: DokuWiki 2026-07-14c from the official `dokuwiki/dokuwiki` image, pinned by digest.
- Headless first-boot install: admin account from `ADMIN_USER` / `ADMIN_PASSWORD`, access control on, self-registration off, Railway's proxy trusted for HTTPS and host detection.
- Health check at `/healthz` (alias of the upstream `/health.php`).
- All data on the `/storage` volume.
