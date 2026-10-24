# Upgrade from the previous default

Move from `trixie-debian` (Debian PHP 8.4) to `trixie-current` (official PHP
image, PHP 8.5 for the October 2026 cycle). Both use Debian Trixie.

## 1. Update the build files

Back up your Compose files and custom configuration. Update your existing
checkout with `git pull --ff-only`, keeping local project changes when merging.
If you use a fresh clone, carry over your project configuration and keep bind
mounts pointing to the existing host files and data.

Keep your mounts, Apache overrides, custom entrypoint, ports, permissions,
environment and secrets. Your application and local/NFS data stay in place.

## 2. Select the new build

In your existing Compose file, set:

```yaml
services:
  web:
    build:
      context: .
      dockerfile: Dockerfile.trixie-current
```

Keep the rest of your Compose configuration. If you use variant `-f` options,
replace `docker-compose.trixie-debian.yml` with
`docker-compose.trixie-current.yml`. Keep your other overrides and their order.

## 3. Update custom PHP mounts

If you mount PHP configuration files, change their **container targets**:

| Old target | New target |
| --- | --- |
| `/etc/php/8.4/apache2/conf.d/<name>.ini` | `/usr/local/etc/php/conf.d/<name>.ini` |
| `/etc/php/8.4/cli/conf.d/<name>.ini` | `/usr/local/etc/php/conf.d/<name>.ini` |
| `/etc/php/8.4/apache2/php.ini` or `/etc/php/8.4/cli/php.ini` | `/usr/local/etc/php/php.ini` |

The host source can stay unchanged. For example:

```yaml
      - type: bind
        source: ./conf/php/8.4/apache2/conf.d/90-uploads.ini
        target: /usr/local/etc/php/conf.d/90-uploads.ini
        read_only: true
```

Apache and CLI share the new directory: merge duplicated settings and use one
file per target. Mount individual INI files, keeping the image's own `conf.d`
files visible. Review old paths if reusing a full `php.ini`. Remove any old
`/etc/php/8.4/fpm/...` mounts; this build uses Apache without PHP-FPM.

## 4. Check your custom entrypoint

The stock entrypoint is ready. If you use your own, keep its application/worker
logic and replace hardcoded old PHP paths as needed. Use `php` from `PATH`
instead of `/usr/bin/php` or `php8.4`.

If it writes runtime settings to `/tmp/php-conf.d`, preserve the default PHP
scan directory with:

```sh
export PHP_INI_SCAN_DIR=:/tmp/php-conf.d
```

## 5. Build and restart

Use the same Compose project name and your selected `-f` options for every command:

```sh
docker compose config --quiet
docker compose build --pull --no-cache web
docker compose up -d --no-build --no-deps --wait web
docker compose exec -T web php -v
docker compose logs --tail=100 web
```

The build can run while the old container serves requests. Recreation causes a
short interruption and preserves the configured mounts. Check your application,
data access, PHP limits and workers afterwards.

See [runtime configuration](conf.md) for more detail and the
[README smoke tests](../README.md#python-and-aaf-tools-all-builds) for Python/AAF
and media checks.
