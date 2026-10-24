# PHP + Apache (Debian) — Hardened Docker Compose

Production-ready Docker setup for PHP + Apache on Debian.

### Current default: Debian Trixie with upstream stable tools

`Dockerfile.trixie-current` uses Debian Trixie with the official stable PHP/Apache
and Python images. It builds the latest stable FFmpeg and ImageMagick releases
from source, installs stable Imagick from PECL, and installs the latest compatible
stable PHPMailer and `pyaaf2` releases from Composer and PyPI respectively.

For the October 2026 cycle, the stable image tags select PHP **8.5** and Python
**3.15**. These tags deliberately follow newer stable series on fresh builds;
the previous and compatibility recipes retain their existing PHP series.

- PHP with Apache, PDO (`pdo_mysql`, `pdo_sqlite`), ZIP and Imagick
- Python 3 with venv support and `pyaaf2` in `/opt/pyaaf2/venv`
- Imagick with **HEIC/AVIF** support
- `ffmpeg` with **HEVC/H.265** support
- PHPMailer globally autoloaded
- **OPcache disabled by default**
- Runs as **non-root** and supports a **read-only** root filesystem

The source builds take longer than installing Debian media packages. A fresh
build follows upstream stable releases; cached layers retain their existing
versions. Use the PHP diagnostic page and Python checks below to inspect a built image.

### Previous default and compatibility builds

`docker-compose.trixie-debian.yml` retains the previous default: Debian 13,
Debian-packaged PHP **8.4**, ImageMagick **7**, `php-imagick` **3.8.x**, FFmpeg
and PHPMailer from Debian packages. Its PHP and media package choices are
preserved, with the shared Python/AAF tools added.

Moving a project to the current default also switches from Debian-packaged PHP
to the official PHP layout. Existing projects should follow
[Upgrade an existing installation](notes/upgrade.md),
including the PHP INI mount and custom entrypoint changes.
Select `docker-compose.trixie-debian.yml` explicitly to retain the previous
PHP 8.4/media stack and INI layout with the Python/AAF addition.

The original Trixie/PHP **8.3** and Bookworm/PHP **8.3** variants are retained for
existing projects. Bookworm with Debian PHP **8.2** is a legacy option for
existing deployments, rather than the starting point for new projects.
See [Build choices](notes/builds.md) for all five variants.

---

## Setup

The following steps are for a new installation. For an existing deployment, use
[Upgrade an existing installation](notes/upgrade.md).

#### Clone the repository (replace `webserver01` with your project folder name)
```
git clone https://github.com/theoppermann/php-media-kit.git webserver01
cd webserver01
```
#### Create the default directories
```
mkdir -p ./www/cache ./www/data ./data ./secrets ./conf/apache-conf
sudo chown -R 33:33 ./data
sudo chmod -R 750 ./data
```
`./data` is mounted at `/var/www/html/data` by the default Compose file.
With the stock virtual host, this directory is inside the document root and
can be served at `/data/`. Projects set their own storage mount, document root
and access rules in their Compose and Apache configuration. See
[Data access and the legacy /files alias](notes/dev.md#data-access-and-the-legacy-files-alias).

#### Create the mail secret
```
echo "super-secret-password" > secrets/mail_pass.txt
```
#### Create the health endpoint
The `./www` bind mount hides the health endpoint baked into the image.
```
echo "<?php http_response_code(200); echo 'OK';" > www/health.php
```
If your project changes the document root, create `health.php` under that root
so the `/health.php` health check still works.

#### Build and run
`docker-compose.yml` selects `Dockerfile.trixie-current` by default:
```
docker compose up -d --build
```
To use the previous default with Debian-packaged PHP 8.4, add its Compose override:
```
docker compose -f docker-compose.yml -f docker-compose.trixie-debian.yml up -d --build
```
The retained compatibility choices are `docker-compose.trixie-im7.yml`,
`docker-compose.bookworm-php.yml` and `docker-compose.bookworm-debian.yml`.
`docker-compose.trixie-current.yml` selects the current default explicitly.
Use the same two `-f` options for later `build`, `up`, `down`, and `logs`
commands when using an alternative. To force a fresh build, run
`docker compose build --no-cache --pull` with the same options before `up`.

#### Stop
```
docker compose down
```
#### View logs
```
docker compose logs -f
```
Add the selected override to these commands if you are using an alternative.

#### Check the container name with:
```
docker ps
```
---

#### Verify the image features with the included PHP test page
```
cp index.php www/index.php
```
Open `http://<server-ip>/` in a browser. Include the published port if you change
the default host port of 80.

#### Python and AAF tools (all builds)

All five builds include Python 3, venv support and the latest compatible stable
`pyaaf2` release available on PyPI when the installation step runs. The library
is imported as `aaf2`:

```sh
docker compose exec -T web /opt/pyaaf2/venv/bin/python -c "import aaf2; from importlib.metadata import version; print(version('pyaaf2'))"
```

Use `/opt/pyaaf2/venv/bin/python` directly; activation is unnecessary. The venv is
installed during the image build, outside the code and data mounts. It is
root-owned and readable/executable by the web user (UID 33), including with a
read-only root filesystem. Temporary files belong in `/tmp`, which is writable
and mounted as tmpfs; its contents are discarded when the container stops.

The package version is not pinned. Docker may reuse a cached installation layer;
use the fresh-build command above (`--no-cache --pull`) to fetch current releases.
No Python packages are installed at container startup.

Run the AAF and temporary-file smoke test as the configured web user:

```sh
docker compose exec -T web /opt/pyaaf2/venv/bin/python - < tests/python-aaf-smoke.py
```

Include the same variant `-f` options if you are using an alternative build.

#### Media codec smoke test

Test real HEIC/AVIF decoding and PNG thumbnails, HEIC/AVIF encoding roundtrips,
and FFmpeg HEVC/H.265 encoding and decoding on the current build:

```sh
docker compose exec -T web /opt/pyaaf2/venv/bin/python - --heif-encode < tests/media-smoke.py
```

For the previous and compatibility builds, omit `--heif-encode` to test their
existing decoder support and HEVC/H.265 encoding/decoding. Their original media
package choices and encoder availability are preserved.

The test downloads pinned, hash-checked libheif example images into `/tmp` and
removes its temporary files afterwards. For offline tests, pass
`--fixtures /path/in/container` containing `example.heic` and `example.avif` from
the sources recorded in the test script. Use the same variant and project
options as for your other Compose commands.

---

#### Configuration

- **Development and writable mounts** – see [Development configuration](notes/dev.md).
- **PHP settings** – see [Configurations](notes/conf.md) for the Compose environment variables.
- **Apache overrides** – The stock virtual host loads `.conf` files mounted from `./conf/apache-conf/`.
  Projects using a replacement virtual host choose which configuration to include there.
  See [Custom Apache settings](notes/override.md) for details and examples.
- **HTTPS/reverse proxy** – see [Reverse-proxy notes](notes/traefik.md) and the
  [Legacy Traefik page](notes/traefik_legacy.md).

---

#### Notes

- When hosting multiple projects, give each deployment a unique Compose project name
  with `-p <project-name>` or `COMPOSE_PROJECT_NAME`. Compose generates image names
  from the project and service, such as `<project-name>-web`. Also remove or
  override the fixed `container_name: webserv01` and host port `80` for each
  deployment to avoid container-name and port collisions. Use the same project
  name for each Compose command for that deployment.
- Different image tags can still share an image ID or layers when their content
  is identical. Docker's storage deduplication does not share the containers'
  runtime configuration or data mounts.
- Logs: `docker logs <container-name>`
- Exec: `docker exec -it <container-name> sh`
- Root filesystem is read-only
- /tmp is mounted as tmpfs
- Keep secrets and runtime data out of Git; the included `.gitignore` provides the default exclusions
- See [Third-party notices](THIRD_PARTY_NOTICES.md) for the included software and license references.


