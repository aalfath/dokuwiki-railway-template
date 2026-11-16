[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/dokuwiki?utm_medium=integration&utm_source=button&utm_campaign=dokuwiki)

# DokuWiki on Railway

One-click [DokuWiki](https://www.dokuwiki.org/) for [Railway](https://railway.com): the simple, file-based wiki that needs no database. Every page is a plain text file on a Railway volume.

## What this template deploys

| Service | Source | Notes |
|---|---|---|
| `DokuWiki` | this repo (`Dockerfile`) | Official image `dokuwiki/dokuwiki:2026-07-14c` pinned by digest, Apache + PHP 8.4, volume at `/storage`, health check `/healthz` |

DokuWiki version: **2026-07-14c** (latest stable release).

The wrapper in this repo is small:

- `railway-start.sh` makes Apache listen on `PORT`, keeps only Apache's `mpm_prefork` module (Railway's build can re-enable `mpm_event`, and Apache then won't start), prepares the `/storage` volume with the upstream setup script, runs the first-boot installer, and starts Apache the way the upstream entrypoint does.
- `railway-healthz.conf` serves the upstream health check (`/health.php`) as `/healthz` too, because Railway's health check path can't contain a dot.
- `railway-install.php` does what DokuWiki's web installer does, without the browser: on the first boot it creates the admin account from `ADMIN_USER` / `ADMIN_PASSWORD`, turns on access control, disables self-registration and trusts Railway's proxy for HTTPS detection. So `install.php` is never left open for whoever reaches the site first. On later boots it changes nothing, so settings you make in the admin UI stay.

## Variables

| Variable | Default | Purpose |
|---|---|---|
| `ADMIN_PASSWORD` | generated (`${{secret(24)}}`) | Password of the first admin. Used on the first boot only; change it later under *Update Profile* |
| `ADMIN_USER` | `admin` | Login of the first admin (first boot only) |
| `PORT` | `8080` | Port Apache listens on |

Optional, read on the first boot only (add them before the first deploy if you want them): `ADMIN_EMAIL` (default `admin@example.com`), `ADMIN_FULLNAME`, `WIKI_TITLE` (default `DokuWiki`), `WIKI_ACL_POLICY` (`0` open, `1` public: everyone reads, signed-in users edit (default), `2` closed), `WIKI_ALLOW_REGISTER` (`1` to allow self-registration), `WIKI_LICENSE` (default `cc-by-sa`), `WIKI_LANG` (default `en`). The image also reads `PHP_UPLOADLIMIT` (default `128M`), `PHP_MEMORYLIMIT` (default `256M`) and `PHP_TIMEZONE` (default `UTC`) on every boot.

## Data

Everything lives on the volume at `/storage`: pages, media, revisions, users, configuration, and plugins or templates you install from the Extension Manager. Bundled plugins and templates come from the image, so they update with it.

## Updates

This template builds from this repository. When the pinned DokuWiki version is bumped here, Railway shows deployers an "update available" notice; they apply it when they choose. Read [CHANGELOG.md](CHANGELOG.md) before applying an update. Back up the volume first for major DokuWiki releases.

## Local test

```sh
docker build -t dokuwiki-railway .
docker run --rm -p 8080:8080 -e ADMIN_PASSWORD=change-me-please -v dokuwiki-data:/storage dokuwiki-railway
```

## License

The wrapper files in this repo are MIT. DokuWiki itself is GPL-2.0, see [dokuwiki/dokuwiki](https://github.com/dokuwiki/dokuwiki).
