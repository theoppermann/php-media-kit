# PHP + Apache (Debian) — Hardened Docker Compose

PHP + Apache on Debian Trixie, with upstream stable Python and media tools.

- PHP with PDO (MySQL/SQLite), ZIP and PHPMailer
- Imagick with **HEIC/AVIF** support
- FFmpeg with **HEVC/H.265** support
- Python 3, venv and `pyaaf2` in `/opt/pyaaf2/venv`
- Runs as **non-root** with a **read-only** root filesystem
- **OPcache disabled by default**

## Setup

For an existing installation, see the [upgrade guide](notes/upgrade.md).

### Clone

Replace `webserver01` with your project folder name:

```sh
git clone https://github.com/theoppermann/php-media-kit.git webserver01
cd webserver01
```

### Create directories

```sh
mkdir -p ./www/cache ./www/data ./data ./secrets ./conf/apache-conf
sudo chown -R 33:33 ./data
sudo chmod -R 750 ./data
```

### Create the mail secret

```sh
echo "super-secret-password" > secrets/mail_pass.txt
```

### Create the health endpoint

The container health check requires `/health.php`:

```sh
echo "<?php http_response_code(200); echo 'OK';" > www/health.php
```

### Build and run

```sh
docker compose up -d --build
```

### Stop

```sh
docker compose down
```

### View logs

```sh
docker compose logs -f
```

## Documentation

- [Build choices and alternatives](notes/builds.md)
- [Upgrading an existing installation](notes/upgrade.md)
- [PHP and runtime settings](notes/conf.md)
- [Apache overrides](notes/override.md)
- [Development, mounts and multiple projects](notes/dev.md)
- [Python and AAF tools](notes/python.md)
- [Verification and media tests](notes/testing.md)
- [HTTPS/reverse proxy](notes/traefik.md) and [legacy notes](notes/traefik_legacy.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
