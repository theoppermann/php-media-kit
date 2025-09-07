# syntax=docker/dockerfile:1.7

############################
# Stage 1: PHPMailer only
############################
FROM composer:2 AS deps
WORKDIR /app
RUN composer init --no-interaction --name=temp/temp \
 && composer require --no-interaction --no-plugins --no-scripts phpmailer/phpmailer:^6.9 \
 && composer dump-autoload --optimize

############################
# Stage 2: Runtime (lean & secure)
############################
FROM php:8.3-apache-bookworm

ENV DEBIAN_FRONTEND=noninteractive TZ=Europe/Copenhagen \
    # Let PHP also scan a runtime-writable dir (for ENV overrides)
    PHP_INI_SCAN_DIR="/usr/local/etc/php/conf.d:/tmp/php-conf.d"

# ---- Runtime libs (official Debian) ----
# - ImageMagick + HEIC (libheif1 + libde265-0) for Imagick
# - ffmpeg with HEVC/H.265 + HEIF support (Debian build)
# - zip CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates tzdata curl \
      imagemagick libheif1 libde265-0 libmagickwand-6.q16-6 \
      ffmpeg zip \
      libsqlite3-0 libmariadb-dev libzip4 zlib1g \
 && rm -rf /var/lib/apt/lists/*

# ---- PHP extensions (PDO full + ZIP) + PECL imagick ----
# NOTE: imagick needs ImageMagick dev headers (libmagickwand-6.q16-dev)
RUN apt-get update && apt-get install -y --no-install-recommends \
      $PHPIZE_DEPS \
      libzip-dev zlib1g-dev libsqlite3-dev \
      libmagickwand-6.q16-dev \
 && docker-php-ext-install -j"$(nproc)" pdo_mysql pdo_sqlite zip \
 && pecl install imagick \
 && docker-php-ext-enable imagick \
 && apt-get purge -y \
      $PHPIZE_DEPS libzip-dev zlib1g-dev libsqlite3-dev libmagickwand-6.q16-dev \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ---- Apache hardening + basic headers + log to stdout (build-time, OK to touch /etc here) ----
RUN a2enmod rewrite headers deflate expires \
 && a2dismod -f autoindex status \
 && { \
      echo "ServerTokens Prod"; \
      echo "ServerSignature Off"; \
      echo "TraceEnable Off"; \
      echo 'Header always set X-Content-Type-Options "nosniff"'; \
      echo 'Header always set X-Frame-Options "DENY"'; \
      echo 'Header always set X-XSS-Protection "1; mode=block"'; \
    } > /etc/apache2/conf-available/security.conf \
 && a2enconf security \
 && { \
      echo "<Directory /var/www/>"; \
      echo "  Options -Indexes -Includes -ExecCGI"; \
      echo "  AllowOverride All"; \
      echo "  Require all granted"; \
      echo "</Directory>"; \
    } > /etc/apache2/conf-available/security-extra.conf \
 && a2enconf security-extra \
 && { echo 'ErrorLog /proc/self/fd/2'; echo 'CustomLog /proc/self/fd/1 combined'; } \
    > /etc/apache2/conf-available/log-to-stdout.conf \
 && a2enconf log-to-stdout

# ---- Switch Apache to :8080 so we can run fully non-root ----
RUN sed -ri 's/^Listen 80/Listen 8080/' /etc/apache2/ports.conf \
 && sed -ri 's/<VirtualHost \*:80>/<VirtualHost *:8080>/' /etc/apache2/sites-available/000-default.conf

# ---- Minimal health endpoint ----
RUN printf "%s\n" "<?php http_response_code(200); echo 'OK';" > /var/www/html/health.php

# ---- Bundle PHPMailer vendor tree (runtime does not include Composer) ----
RUN mkdir -p /usr/local/lib/php-vendor
COPY --from=deps /app/vendor /usr/local/lib/php-vendor/phpmailer

# ---- Code immutability ----
RUN chown -R root:root /var/www \
 && find /var/www -type d -exec chmod 755 {} \; \
 && find /var/www -type f -exec chmod 644 {} \;

# ---- Entrypoint (no runtime writes to /etc) ----
COPY docker-php-entrypoint.sh /usr/local/bin/docker-php-entrypoint
RUN chmod +x /usr/local/bin/docker-php-entrypoint

WORKDIR /var/www/html
USER www-data

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -fsS http://localhost:8080/health.php || exit 1

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["apache2ctl","-D","FOREGROUND"]
