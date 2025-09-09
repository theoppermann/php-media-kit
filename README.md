# PHP + Apache (Debian) — Hardened Container

Production-ready Docker setup for PHP + Apache on Debian, with two flavors:

## Flavors

### 1) Pure Debian (apt-only)
Everything (PHP, Imagick, ImageMagick, FFmpeg) is installed from Debian’s APT repos.  
**Pros:** one update channel (`apt`), Debian hardening, lowest maintenance.  
**Variants:**
- **Trixie – pure Debian (recommended):** `docker-compose.trixie-debian.yml`  
  Debian 13 • PHP **8.4** • ImageMagick **7** • `php-imagick` **3.8.x**
- **Bookworm – pure Debian:** `docker-compose.bookworm-debian.yml`  
  Debian 12 • PHP **8.2** • ImageMagick **6** • `php-imagick` **3.7.x**

### 2) Upstream PHP + PECL
Uses official `php:*` images for PHP; Imagick is installed from **PECL**. Debian APT is still used for FFmpeg/ImageMagick.  
**Pros:** easy to pin Imagick version and use upstream PHP features. **Note:** not “apt-only”.  
**Variants:**
- **Trixie – php:8.3-apache + IM7:** `docker-compose.trixie-im7.yml`  
  Debian 13 base • PHP **8.3** (from `php:*`) • ImageMagick **7** • PECL `imagick` **3.8.0**
- **Bookworm – php:8.3-apache:** `docker-compose.bookworm-php.yml`  
  Debian 12 base • PHP **8.3** (from `php:*`) • ImageMagick **6** • PECL `imagick` **3.8.0**

### Common features (all variants)

- PDO (`pdo_mysql`, `pdo_sqlite`)
- Imagick with **HEIC/AVIF** support
- `ffmpeg` with **HEVC/H.265**
- PHPMailer bundled (vendor tree)
- ZIP extension
- **OPcache disabled by default**
- Runs as **non-root** and supports **read-only** root filesystem

### Quick choose

- Want newest Debian stack and **apt-only** updates? → **`docker-compose.trixie-debian.yml`** (recommended)  
- Must stay on Debian 12? → **`docker-compose.bookworm-debian.yml`**  
- Prefer the official `php:*` images or need to **pin Imagick via PECL**? → **`docker-compose.trixie-im7.yml`** or **`docker-compose.bookworm-php.yml`**

---


## Setup

#### Clone the repository (replace `webserver01` with your project folder name)
```
git clone https://github.com/theoppermann/php-apache-imagick-ffmpeg.git webserver01
cd webserver01
```
#### Create the mail secret
```
mkdir -p secrets
echo "super-secret-password" > secrets/mail_pass.txt
```
#### Build & run

Replace <override> with one of:

- docker-compose.trixie-debian.yml (recommended)

- docker-compose.trixie-im7.yml

- docker-compose.bookworm-php.yml

- docker-compose.bookworm-debian.yml

#### Build
```
docker compose -f docker-compose.yml -f <override> build --no-cache --pull
```

#### Run
```
docker compose -f docker-compose.yml -f <override> up -d
```

#### Stop
```
docker compose -f docker-compose.yml -f <override> down
```
#### View logs
```
docker logs -f <the name of the container> or
docker compose -f docker-compose.yml -f <override> logs -f
```

#### Check the container name with:
```
docker ps
```
---

#### Verification
```
docker exec -it <the name of the container> sh -lc '
php -m | grep -E "PDO|pdo_mysql|pdo_sqlite|zip|imagick";
php -i | grep -i "^opcache.enable";
convert -list format | grep -Ei "heic|heif|avif";
ffmpeg -hide_banner -codecs | grep -i hevc;
php -r "require \"/usr/local/lib/php-vendor/phpmailer/autoload.php\"; echo \"PHPMailer OK\n\";"
'

```
#### Expected output:
```
PDO, pdo_mysql, pdo_sqlite, zip, imagick
opcache.enable => Off
HEIC / AVIF listed in ImageMagick
hevc codecs listed in ffmpeg
PHPMailer OK
```
---

#### Configuration

Edit docker-compose.yml to set environment variables:

- PHP i this is empty it will fallback to defaults
```
PHP_MEMORY_LIMIT:
PHP_UPLOAD_MAX_FILESIZE:
PHP_POST_MAX_SIZE:
PHP_MAX_EXECUTION_TIME:
OPCACHE_ENABLE:
PHP_TZ:
```

- Optional toggles (uncomment if/when needed)
```
APACHE_SERVER_NAME
TRUSTED_PROXIES
HSTS
CSP
APP_WRITABLE_DIRS
```
- Mail: Remember to use your own mail info and put passwords in secrets.
```
MAIL_HOST: "smtp.example.com"
MAIL_PORT: "587"
MAIL_SECURE: "tls"
MAIL_USER: "user@example.com"
MAIL_PASS_FILE: "/run/secrets/mail_pass"
```
---

### Notes

- You migh want t change the container_name: webserv01 in the compose file
- Logs: docker logs <the name of the container>
- Exec: docker exec -it <the name of the container> sh
- Root filesystem is read-only
- /tmp is mounted as tmpfs
- Only directories listed in APP_WRITABLE_DIRS are writable
- Keep secrets and userdata / cache out of Git (add it to .gitignore)
