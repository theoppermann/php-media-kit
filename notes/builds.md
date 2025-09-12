### Alternatives

This stack supports multiple Debian + PHP + Imagick combinations.  
Pick the variant that matches your environment:

- **Debian Trixie (apt-only):**  
  `docker-compose.trixie-debian.yml`  
  - Debian 13 • PHP **8.4** (from Debian’s repos)  
  - ImageMagick **7** + `php-imagick` **3.7.x** (apt package)  
  - ✅ Recommended: simplest setup, no PECL build step, fully managed by apt.  

- **Debian Bookworm (apt-only):**  
  `docker-compose.bookworm-debian.yml`  
  - Debian 12 • PHP **8.2** (from Debian’s repos)  
  - ImageMagick **6** + `php-imagick` **3.7.x** (apt package)  
  - 🕰 Choose this only if you must stay on Debian 12 LTS.  

- **Debian Trixie + official PHP (PECL imagick):**  
  `docker-compose.trixie-im7.yml`  
  - Debian 13 • PHP **8.3/8.4** (from official `php:*` images)  
  - ImageMagick **7** + PECL `imagick` **3.8.0** (built during image build)  
  - 🐘 Use this if you prefer upstream PHP releases or need imagick pinned via PECL.  

- **Debian Bookworm + official PHP (PECL imagick):**  
  `docker-compose.bookworm-php.yml`  
  - Debian 12 • PHP **8.3** (from official `php:*` images)  
  - ImageMagick **6** + PECL `imagick` **3.8.0** (built during image build)  
  - Legacy option if you need PHP 8.3 on Debian 12.  

---

### Quick choose

- ✅ **Want newest Debian stack, minimal maintenance, and apt-only updates?**  
  → `docker-compose.trixie-debian.yml` (recommended)

- 🕰 **Stuck on Debian 12 LTS?**  
  → `docker-compose.bookworm-debian.yml`

- 🐘 **Prefer official `php:*` images or need to pin imagick via PECL?**  
  → `docker-compose.trixie-im7.yml` (Debian 13)  
  → `docker-compose.bookworm-php.yml` (Debian 12, legacy)
