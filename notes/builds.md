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
