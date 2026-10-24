### Build choices

Five builds are available. `docker-compose.yml` selects the current default,
`Dockerfile.trixie-current`. Add the matching variant Compose file when choosing
another build, and use the same files for every Compose command.

### Current default: upstream stable tools on Debian Trixie

`docker-compose.trixie-current.yml` / `Dockerfile.trixie-current`

The October 2026 cycle starts with PHP **8.5** and Python **3.15**. The image tags
float with the stable channels, so later fresh builds can select newer stable
series. The previous and compatibility recipes retain their existing PHP series.

- Debian 13 with the official stable `php:apache-trixie` image.
- Python 3 from the official stable `python:3-slim-trixie` image, with venv support.
- Latest stable ImageMagick and FFmpeg built from source, with HEIC/AVIF and HEVC/H.265 support.
- Stable Imagick installed from PECL; latest compatible stable PHPMailer from Composer.
- Latest compatible stable `pyaaf2` installed from PyPI.

This is the default for new projects. Versions follow the stable release channels
when their build steps run. Source compilation takes longer than installing
Debian media packages. Cached layers retain the versions previously installed;
use `build --no-cache --pull` with the selected Compose files to refresh the base
images and rerun the installation steps. Use the [verification checks](testing.md)
to inspect a particular image.

To select the previous default, for example:

```sh
docker compose -f docker-compose.yml -f docker-compose.trixie-debian.yml up -d --build
```

Replace the variant filename to choose another build. Keep the same `-f` options
for later build, stop and logs commands. `docker-compose.trixie-current.yml`
selects the current default explicitly.

### Previous default: Debian-packaged PHP 8.4

`docker-compose.trixie-debian.yml` / `Dockerfile.trixie-debian`

- Debian 13 with PHP **8.4** from Debian's repositories.
- ImageMagick **7**, `php-imagick` **3.8.x**, FFmpeg and PHPMailer from Debian packages.
- Debian's Python 3 with venv support and the shared `pyaaf2` installation.

Use this option to retain the previous PHP and media package choices. It has the
common Python/AAF addition; it does not switch PHP or the media tools to upstream
source builds.

### Retained compatibility and legacy builds

These original variants remain available for existing deployments:

- **Trixie with upstream PHP 8.3:** `docker-compose.trixie-im7.yml` /
  `Dockerfile.trixie-im7`. Debian 13, PHP **8.3**, Debian ImageMagick **7** and
  PECL Imagick **3.8.0**.
- **Bookworm with upstream PHP 8.3:** `docker-compose.bookworm-php.yml` /
  `Dockerfile.bookworm-php`. Debian 12, PHP **8.3**, Debian ImageMagick **6** and
  PECL Imagick **3.8.0**.
- **Bookworm with Debian PHP 8.2 (legacy):** `docker-compose.bookworm-debian.yml` /
  `Dockerfile.bookworm-debian`. Debian 12, PHP **8.2**, ImageMagick **6** and
  `php-imagick` **3.7.x** from Debian packages. Retained for existing projects;
  use a Trixie build for new projects.

The compatibility and legacy variants keep their existing PHP and media package
choices and add Debian's Python 3, venv support and `pyaaf2`.

### Shared Python and AAF environment

All five builds install `pyaaf2` into `/opt/pyaaf2/venv` during the image build.
The latest compatible stable library release is selected whenever that
installation step runs. The environment is outside the code/data mounts and is
available to the web user with a read-only root filesystem; `/tmp` remains the
writable, temporary workspace. See [Python and AAF tools](python.md)
for usage and the [AAF smoke test](testing.md#python-and-aaf).

The [media codec smoke test](testing.md#media-codecs) checks real
HEIC/AVIF decoding and HEVC/H.265 encoding/decoding. Enable `--heif-encode` on
the current build to check both image encoders too; compatibility builds retain
their existing encoder availability.
