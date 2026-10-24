# Runtime configuration

All five builds use the same Compose environment variables and entrypoint.
The default selects the current upstream-stable Trixie build; the previous
Debian PHP 8.4 build and the retained compatibility variants are listed in
[Build choices](builds.md).

Edit `services.web.environment` in your Compose configuration. Recreate the
container with `docker compose up -d` after changing environment variables;
`restart` alone does not load new Compose settings. Include the same selected
variant `-f` options and project name (`-p` or `COMPOSE_PROJECT_NAME`) in later
commands for that deployment.

### PHP settings

These optional overrides are written to `/tmp/php-conf.d/zz-runtime.ini` at
startup. An unset or empty value retains the corresponding image default.

```yaml
PHP_MEMORY_LIMIT: 256M
PHP_UPLOAD_MAX_FILESIZE: 2000M
PHP_POST_MAX_SIZE: 2000M
PHP_MAX_EXECUTION_TIME: 120
PHP_MAX_FILE_UPLOADS: "1000"
PHP_MAX_INPUT_VARS: "50000"
PHP_MAX_MULTIPART_BODY_PARTS: "5000"
OPCACHE_ENABLE: "0"
OPCACHE_ENABLE_CLI: "0"
PHP_TZ: "Europe/Copenhagen"
```

`PHP_MAX_MULTIPART_BODY_PARTS` is applied only on PHP 8.4 or newer. Older retained
PHP variants ignore it. OPcache is disabled in the images unless enabled through
these overrides.

### PHP configuration layout and migration

Project-specific PHP INI bind mounts must target the selected PHP distribution's
scan directories:

| Build variant | Apache INI scan directory | CLI INI scan directory |
| --- | --- | --- |
| `trixie-current`, `trixie-im7`, `bookworm-php` | `/usr/local/etc/php/conf.d` | `/usr/local/etc/php/conf.d` |
| `trixie-debian` | `/etc/php/8.4/apache2/conf.d` | `/etc/php/8.4/cli/conf.d` |
| `bookworm-debian` | `/etc/php/8.2/apache2/conf.d` | `/etc/php/8.2/cli/conf.d` |

The stock entrypoint preserves each build's default INI scanning and adds the
shared `/tmp/php-conf.d` directory for runtime overrides. Custom entrypoints
should preserve that behavior. Forcing a Debian-specific scan path in an
official PHP image can omit its installed extension and application settings.

When moving from the previous default to `trixie-current`, review both custom
INI mounts and entrypoint behavior. Existing projects can select
`docker-compose.trixie-debian.yml` explicitly to keep the PHP 8.4/media package
choices and Debian INI layout, with the shared Python/AAF tools added.

### Apache and writable directories

Set these only when your project needs them:

```text
APACHE_SERVER_NAME
TRUSTED_PROXIES
HSTS
CSP
CSP_REPORT_ONLY
APP_WRITABLE_DIRS
```

`TRUSTED_PROXIES` is a comma-separated list of proxy addresses or networks for
Apache's real-client-IP handling. Configure it to match your own reverse proxy.
`APP_WRITABLE_DIRS` is a space-separated list of directories the web user can
create or adjust; it does not make a read-only mount writable or change ownership.
See [Development and mounts](dev.md), [Apache overrides](override.md) and
[Reverse-proxy notes](traefik.md) for the relevant project configuration.

### Python and AAF tools

Every build installs Python with venv support and `pyaaf2` at image-build time.
Use `/opt/pyaaf2/venv/bin/python` directly and import the library as `aaf2`.
No entrypoint toggle or runtime package installation is needed. The root-owned
environment can be executed with a read-only root filesystem; use `/tmp` for
temporary files. Persistent output belongs in a configured data mount.

The current build follows the upstream stable Python image; the previous and
compatibility builds use their Debian Python packages. Rebuild with
`--no-cache --pull` to refresh the unpinned stable `pyaaf2` installation and the
selected build's release channels. See the [Python usage and smoke test](../README.md#python-and-aaf-tools-all-builds).

### Mail configuration

Use your project's SMTP details and place the password in a Compose secret:

```yaml
MAIL_HOST: "smtp.example.com"
MAIL_PORT: "587"
MAIL_SECURE: "tls"
MAIL_USER: "user@example.com"
MAIL_PASS_FILE: "/run/secrets/mail_pass"
```

The base Compose file mounts `./secrets/mail_pass.txt` at `/run/secrets/mail_pass`.
Applications must read these settings and the secret file when configuring
PHPMailer; installing the library does not configure an SMTP account automatically.
