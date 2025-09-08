#!/bin/sh
set -e
umask 027

# Apache på tmpfs (RO-rootfs venligt)
export APACHE_RUN_DIR=/tmp/apache2
export APACHE_LOCK_DIR=/tmp/apache2
export APACHE_PID_FILE=/tmp/apache2/apache2.pid
mkdir -p "$APACHE_RUN_DIR"

# PHP overrides (skriv kun til /tmp; kræver at PHP_INI_SCAN_DIR inkluderer /tmp/php-conf.d)
mkdir -p /tmp/php-conf.d
: > /tmp/php-conf.d/zz-runtime.ini
[ -n "$PHP_MEMORY_LIMIT" ]        && echo "memory_limit=$PHP_MEMORY_LIMIT" >> /tmp/php-conf.d/zz-runtime.ini
[ -n "$PHP_UPLOAD_MAX_FILESIZE" ] && echo "upload_max_filesize=$PHP_UPLOAD_MAX_FILESIZE" >> /tmp/php-conf.d/zz-runtime.ini
[ -n "$PHP_POST_MAX_SIZE" ]       && echo "post_max_size=$PHP_POST_MAX_SIZE" >> /tmp/php-conf.d/zz-runtime.ini
[ -n "$PHP_MAX_EXECUTION_TIME" ]  && echo "max_execution_time=$PHP_MAX_EXECUTION_TIME" >> /tmp/php-conf.d/zz-runtime.ini
[ -n "$PHP_TZ" ]                  && echo "date.timezone=$PHP_TZ" >> /tmp/php-conf.d/zz-runtime.ini
[ -n "$OPCACHE_ENABLE" ]          && echo "opcache.enable=$OPCACHE_ENABLE" >> /tmp/php-conf.d/zz-runtime.ini

# Byg apache2ctl kommando (ingen writes til /etc)
set -- apache2ctl -D FOREGROUND
[ -n "$APACHE_SERVER_NAME" ] && set -- "$@" -c "ServerName ${APACHE_SERVER_NAME}"

# Proxy awareness (kræver a2enmod remoteip hvis du bruger det)
if [ -n "$TRUSTED_PROXIES" ]; then
  set -- "$@" -c "RemoteIPHeader X-Forwarded-For"
  for ip in $TRUSTED_PROXIES; do
    set -- "$@" -c "RemoteIPTrustedProxy $ip"
  done
  set -- "$@" -c "SetEnvIfNoCase X-Forwarded-Proto https HTTPS=on"
fi

# Sikkerheds-headere (opt-in)
[ -n "$HSTS" ]            && set -- "$@" -c "Header always set Strict-Transport-Security \"${HSTS}\" env=HTTPS"
[ -n "$CSP" ]             && set -- "$@" -c "Header always set Content-Security-Policy \"${CSP}\""
[ -n "$CSP_REPORT_ONLY" ] && set -- "$@" -c "Header always set Content-Security-Policy-Report-Only \"${CSP_REPORT_ONLY}\""

# App-writable dirs (undgå chown som non-root)
if [ -n "$APP_WRITABLE_DIRS" ]; then
  for d in $APP_WRITABLE_DIRS; do
    mkdir -p "$d" || true
    chmod -R 750 "$d" || true
  done
fi

exec "$@"
