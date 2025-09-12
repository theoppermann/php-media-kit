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
#### Make default dirs (See [uploads.md](notes/uploads.md) for legacy `/uploads` setup.)
```
mkdir -p ./www/cache ./data ./secrets
sudo chown -R 33:33 ./data
sudo chmod -R 750 ./data
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

#### Verification to see if everything was build use the included php testfile.
```
cp index.php www/index.php
```
and open ```http://ipaddress``` in a webbrowser

---

#### Configuration
- PHP Modifiers in the compose file see [Configurations](notes/conf.md)
- How to add HTTPS see [Traefik](notes/traefik.md) or [Traefik Legacy](notes/traefik_legacy.md)

---

#### Notes

- You migh want to change or remove container_name: webserv01 in the compose file
- Logs: docker logs <the name of the container>
- Exec: docker exec -it <the name of the container> sh
- Root filesystem is read-only
- /tmp is mounted as tmpfs
- Keep secrets and userdata / cache out of Git (add it to .gitignore)


