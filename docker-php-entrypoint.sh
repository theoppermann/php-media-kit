#!/bin/sh
set -e

# --- Apache runtime on tmpfs (read_only safe) ---
export APACHE_RUN_DIR=/tmp/apache2
export APACHE_LOCK_DIR=/tmp/apache2
export APACHE_PID_FILE=/tmp/apache2/apache2.pid
mkdir -p "$APACHE_RUN_DIR"

# --- PHP overrides (write to /tmp only; keep PHP's true defaults if unset) ---
mkdir -p /tmp/php-conf.d
: > /tmp/php-conf.d/zz-runtime.ini

[ -n "$PHP_MEMORY_LIMIT" ]        && echo "memory_limit=$PHP_MEMORY_LIMIT" >> /tmp/php-conf.d/zz-runtime.ini
[ -n "$PHP_UPLOAD_MAX_FILESIZE" ] && echo "upload_max_filesize=$PHP_UPLOAD_MAX_FILESIZE" >> /tmp/php-conf.d/zz-runtime.ini
[ -n "$PHP_POST_MAX_SIZE" ]       && echo "post_max_size=$PHP_POST_MAX_SIZE" >> /tmp/php-conf.d/zz-runtime.ini
[ -n "$PHP_MAX_EXECUTION_TIME" ]  && echo "max_execution_time=$PHP_MAX_EXECUTION_TIME" >> /tmp/php-conf.d/zz-runtime.ini
[ -n "$PHP_TZ" ]                  && echo "date.timezone=$PHP_TZ" >> /tmp/php-conf.d/zz-runtime.ini
[ -n "$OPCACHE_ENABLE" ]          && echo "opcache.enable=$OPCACHE_ENABLE" >> /tmp/php-conf.d/zz-runtime.ini

# --- Build Apache CLI (use -C/-c flags; NO writes to /etc at runtime) ---
set -- apache2ctl -D FOREGROUND

# Suppress AH00558 if provided
[ -n "$APACHE_SERVER_NAME" ] && set -- "$@" -C "ServerName ${APACHE_SERVER_NAME}"

# Proxy awareness (opt-in)
if [ -n "$TRUSTED_PROXIES" ]; then
  set -- "$@" -c "RemoteIPHeader X-Forwarded-For"
  for ip in $TRUSTED_PROXIES; do
    set -- "$@" -c "RemoteIPTrustedProxy $ip"
  done
  set -- "$@" -c "SetEnvIfNoCase X-Forwarded-Proto \"https\" HTTPS=on"
fi

# Security headers (opt-in)
[ -n "$HSTS" ]            && set -- "$@" -c "Header always set Strict-Transport-Security \"${HSTS}\" env=HTTPS"
[ -n "$CSP" ]             && set -- "$@" -c "Header always set Content-Security-Policy \"${CSP}\""
[ -n "$CSP_REPORT_ONLY" ] && set -- "$@" -c "Header always set Content-Security-Policy-Report-Only \"${CSP_REPORT_ONLY}\""

# Explicit app-writable dirs (everything else stays read-only)
if [ -n "$APP_WRITABLE_DIRS" ]; then
  for d in $APP_WRITABLE_DIRS; do
    mkdir -p "$d" && chown -R www-data:www-data "$d" && chmod -R 750 "$d"
  done
fi

exec "$@"
