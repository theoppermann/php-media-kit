# Upgrade from the previous default

Move from `trixie-debian` (Debian PHP 8.4) to `trixie-current` (official PHP
image, PHP 8.5 for the October 2026 cycle). Both use Debian Trixie.

## Pull and rebuild

With the repository's default Compose and PHP configuration, run from your
existing project directory:

```sh
git pull --ff-only
docker compose up -d --build
```

The updated `docker-compose.yml` already selects `Dockerfile.trixie-current`.
No manual build selection is needed. Keep the same Compose project name,
mounts and project overrides. Your application and local/NFS data stay in place.

Back up custom configuration before updating. If Git reports local changes,
retain them when incorporating the upstream changes. If you have customized
PHP configuration or explicitly selected the old build, apply the relevant
notes below before rebuilding.

## Only for customized setups

### An explicit old build selection

If your own Compose or an override still sets
`dockerfile: Dockerfile.trixie-debian`, change that setting to
`Dockerfile.trixie-current`. If your command includes
`-f docker-compose.trixie-debian.yml`, replace that file with
`docker-compose.trixie-current.yml`. Keep your other overrides and their order.

### Custom PHP mounts

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

### A custom entrypoint

The stock entrypoint is ready. If you use your own, keep its application/worker
logic and replace hardcoded old PHP paths as needed. Use `php` from `PATH`
instead of `/usr/bin/php` or `php8.4`.

If it writes runtime settings to `/tmp/php-conf.d`, preserve the default PHP
scan directory with:

```sh
export PHP_INI_SCAN_DIR=:/tmp/php-conf.d
```

## Check the result

Use the same Compose project name and selected `-f` options for every command:

```sh
docker compose exec -T web php -v
docker compose logs --tail=100 web
```

Recreation causes a short interruption and preserves the configured mounts.
Check your application, data access, PHP limits and workers afterwards.

See [runtime configuration](conf.md) for more detail and the
[README smoke tests](../README.md#python-and-aaf-tools-all-builds) for Python/AAF
and media checks.
