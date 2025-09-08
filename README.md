# PHP + Apache Container

Hardened Docker setup for **PHP 8.3 + Apache** with:

- PDO (`pdo_mysql`, `pdo_sqlite`)
- Imagick with HEIC/AVIF support
- ffmpeg with HEVC/H.265 support
- PHPMailer included
- ZIP extension
- OPcache disabled by default
- Read-only root filesystem, runs as non-root

---

#### Setup

### Clone the repository
```
git clone <YOUR_GIT_REMOTE_URL>
cd <your-project-folder>
```
### Create the mail secret
```
mkdir -p secrets
echo "super-secret-password" > secrets/mail_pass.txt
```

### Build and start
```
docker compose build --no-cache
docker compose up -d
```

### View logs
```
docker logs -f <the name of the container>
```

### Check the container name with:
```
docker ps
```

### Verification
```
docker exec -it <the name of the container> sh -lc '
php -m | grep -E "PDO|pdo_mysql|pdo_sqlite|zip|imagick";
php -i | grep -i "^opcache.enable";
convert -list format | grep -Ei "heic|heif|avif";
ffmpeg -hide_banner -codecs | grep -i hevc;
php -r "require \"/usr/local/lib/php-vendor/phpmailer/autoload.php\"; echo \"PHPMailer OK\n\";"
'

```
### Expected output:
```
PDO, pdo_mysql, pdo_sqlite, zip, imagick
opcache.enable => Off
HEIC / AVIF listed in ImageMagick
hevc codecs listed in ffmpeg
PHPMailer OK
```
### Configuration

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
- Mail Remember to use your own mail info
```
MAIL_HOST: "smtp.example.com"
MAIL_PORT: "587"
MAIL_SECURE: "tls"
MAIL_USER: "user@example.com"
MAIL_PASS_FILE: "/run/secrets/mail_pass"
```
### Notes

- Logs: docker logs <the name of the container>
- Exec: docker exec -it <the name of the container> sh
- Root filesystem is read-only
- /tmp is mounted as tmpfs
- Only directories listed in APP_WRITABLE_DIRS are writable
- Keep secrets and userdata / cache out of Git (add it to .gitignore)
