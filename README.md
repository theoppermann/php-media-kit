# PHP + Apache (Debian) — Hardened Docker Compose

Production-ready Docker setup for PHP + Apache on Debian.

### Debian Trixie (apt-only)
Everything (PHP, Imagick, ImageMagick, FFmpeg) is installed from Debian’s APT repos.  
**Pros:** single update channel (`apt`), Debian hardening, lowest maintenance.  

- `docker-compose.trixie-debian.yml`  
  - Debian 13  
  - PHP **8.4**  
  - ImageMagick **7**  
  - `php-imagick` **3.8.x`  
  - PDO (`pdo_mysql`, `pdo_sqlite`)  
  - Imagick with **HEIC/AVIF** support  
  - `ffmpeg` with **HEVC/H.265**  
  - PHPMailer bundled (vendor tree)  
  - ZIP extension  
  - **OPcache disabled by default**  
  - Runs as **non-root** and supports **read-only** root filesystem  

---

### Alternatives

- **Debian Bookworm (apt-only):**  
  `docker-compose.bookworm-debian.yml`  
  Debian 12 • PHP **8.2** • ImageMagick **6** • `php-imagick` **3.7.x`  
  → Choose this if you must stay on Debian 12.  

- **Debian Trixie + Upstream PHP/PECL:**  
  `docker-compose.trixie-im7.yml`  
  Debian 13 • PHP **8.3** (`php:*` image) • ImageMagick **7** • PECL `imagick` **3.8.0`  
  → Use this if you need official `php:*` images or want to pin Imagick via PECL.  

- **Debian Bookworm + Upstream PHP/PECL:**  
  `docker-compose.bookworm-php.yml`  
  Debian 12 • PHP **8.3** (`php:*` image) • ImageMagick **6** • PECL `imagick` **3.8.0`  
  → Legacy option for Debian 12 with upstream PHP.  

### Quick choose

- Want newest Debian stack and **apt-only** updates? → **`docker-compose.trixie-debian.yml`** (recommended)  
- Must stay on Debian 12? → **`docker-compose.bookworm-debian.yml`**  
- Prefer the official `php:*` images or need to **pin Imagick via PECL**? → **`docker-compose.trixie-im7.yml`** or **`docker-compose.bookworm-php.yml`**

---

### Production vs Development

Configuration is controlled in **`docker-compose.yml`**.  
By default, the stack runs in **production mode** for maximum security:

**Service-level security**
- `read_only: true` → locks the container root filesystem.  
  ⚠️ Keep this enabled in both production **and** development, unless you hit specific issues.  

**Mounts**
- `./www` → bound to `/var/www/html` with `read_only: true` (code is protected).  
- `./uploads` → bound to `/var/www/html/uploads` (persistent, writable by `www-data`).  
- `/var/www/html/cache` → tmpfs mount (in-memory, auto-cleared on restart).  

👉 **For development:** change the `www` bind mount in `docker-compose.yml` to `read_only: false` so you can edit code inside the container.

## Setup

#### Clone the repository (replace `webserver01` with your project folder name)
```
git clone https://github.com/theoppermann/php-apache-imagick-ffmpeg.git webserver01
cd webserver01
```
#### Make default dirs
```
mkdir -p ./www/uploads ./www/cache ./uploads ./secrets
sudo chown -R 33:33 ./uploads
sudo chmod -R 750 ./uploads
```
#### Create the mail secret
```
echo "super-secret-password" > secrets/mail_pass.txt
```
#### Build
```
docker compose -f docker-compose.yml -f docker-compose.trixie-debian.yml build --no-cache --pull
```
#### Alternative builds 
```
docker compose -f docker-compose.yml -f <override> build --no-cache --pull"
```
Replace ``` <override> ```with one of:

- docker-compose.trixie-debian.yml (recommended)

- docker-compose.trixie-im7.yml

- docker-compose.bookworm-php.yml

- docker-compose.bookworm-debian.yml


#### Run
```
docker compose up -d
```

#### Stop
```
docker compose down
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

- You migh want to change or remove container_name: webserv01 in the compose file
- Logs: docker logs <the name of the container>
- Exec: docker exec -it <the name of the container> sh
- Root filesystem is read-only
- /tmp is mounted as tmpfs
- Only directories listed in APP_WRITABLE_DIRS are writable
- Keep secrets and userdata / cache out of Git (add it to .gitignore)

### Optional: Framework Uploads (/uploads)

By default this stack uses /data for safe, public media (served at /files/, with PHP disabled).
Some frameworks and legacy apps expect a writable folder inside the web root at /var/www/html/uploads.

If your app requires this, enable it as follows:
- Create host directory
```
mkdir -p ./uploads
sudo chown -R 33:33 ./uploads
sudo chmod -R 750 ./uploads
```
- Add to your docker-compose.yml:
```
  services:
  web:
    volumes:
      - type: bind
        source: ./uploads
        target: /var/www/html/uploads
```
#### ⚠️ Security note:

By default, files in /uploads can be executed as PHP if uploaded.
If your framework only stores static files there (images, documents), you should harden it by disabling PHP execution:

- Create an override file:

apache-conf/uploads.override.conf
```
<Directory /var/www/html/uploads>
  php_admin_flag engine off
  <FilesMatch "\.php$">
    Require all denied
  </FilesMatch>
</Directory>
```

- In docker-compose.yml, locate the existing commented block:
```
# - type: bind
#   source: ./apache-conf/uploads.override.conf
#   target: /etc/apache2/conf-enabled/99-uploads-override.conf
#   read_only: true
```
Uncomment it to activate the override.

🔒 Recommendation:
Use /data whenever possible.
Only enable /uploads if your framework really requires it.

If you do enable it, also activate the uploads.override.conf unless your framework needs to run PHP code from /uploads (rare and unsafe).
