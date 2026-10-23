# PHP + Apache (Debian) — Hardened Docker Compose

Production-ready Docker setup for PHP + Apache on Debian.

### Debian Trixie (apt-only)
Everything (PHP, Imagick, ImageMagick, FFmpeg) is installed from Debian’s APT repos.  
**Pros:** single update channel (`apt`), Debian hardening, lowest maintenance.  

- `docker-compose.trixie-debian.yml`  
  - Debian 13  
  - PHP **8.4**  
  - ImageMagick **7**  
  - `php-imagick` **3.8.x**
  - PDO (`pdo_mysql`, `pdo_sqlite`)  
  - Imagick with **HEIC/AVIF** support  
  - `ffmpeg` with **HEVC/H.265**  
  - PHPMailer installed from Debian packages and globally autoloaded
  - ZIP extension  
  - **OPcache disabled by default**  
  - Runs as **non-root** and supports **read-only** root filesystem  


#### Alternative builds

- **Debian Bookworm (apt-only):** Debian 12 • PHP **8.2** • ImageMagick **6** • `php-imagick` **3.7.x**
- **Debian Trixie + Upstream PHP/PECL:** Debian 13 • PHP **8.3** (`php:*` image) • ImageMagick **7** • PECL `imagick` **3.8.0**
- **Debian Bookworm + Upstream PHP/PECL:** Debian 12 • PHP **8.3** (`php:*` image) • ImageMagick **6** • PECL `imagick` **3.8.0**

Read more about the alternative builds here [Alternative builds](notes/builds.md)

---

## Setup

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
`docker-compose.yml` uses Debian Trixie by default:
```
docker compose up -d --build
```
For another build, add its Compose override. For example, Debian Bookworm
with upstream PHP:
```
docker compose -f docker-compose.yml -f docker-compose.bookworm-php.yml up -d --build
```
The other choices are `docker-compose.bookworm-debian.yml` and
`docker-compose.trixie-im7.yml`. The existing
`docker-compose.trixie-debian.yml` also selects the default build explicitly.
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

---

#### Configuration

- **Development and writable mounts** – see [Development configuration](notes/dev.md).
- **PHP settings** – see [Configurations](notes/conf.md) for the Compose environment variables.
- **Apache overrides** – The stock virtual host loads `.conf` files mounted from `./conf/apache-conf/`.
  Projects using a replacement virtual host choose which configuration to include there.
  See [Custom Apache settings](notes/override.md) for details and examples.
- How to add **HTTPS** - see [Traefik](notes/traefik.md) or [Traefik Legacy](notes/traefik_legacy.md)

---

#### Notes

- You may want to change or remove `container_name: webserv01` in the Compose file
- Logs: `docker logs <container-name>`
- Exec: `docker exec -it <container-name> sh`
- Root filesystem is read-only
- /tmp is mounted as tmpfs
- Keep secrets and runtime data out of Git; the included `.gitignore` provides the default exclusions


