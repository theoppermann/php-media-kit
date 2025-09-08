#!/bin/sh
set -e
umask 027

# --- Detect PHP major.minor (e.g., 8.4) and expose a writable ini scan dir
PHP_VERS="$(php -r 'printf("%d.%d", PHP_MAJOR_VERSION, PHP_MINOR_VERSION);')"
export PHP_INI_SCAN_DIR="/etc/php/${PHP_VERS}/apache2/conf.d:/tmp/php-conf.d"

# --- Apache runtime on tmpfs (keeps rootfs read-only)
export APACHE_RUN_DIR=/tmp/apache2
export APACHE_LOCK_DIR=/tmp/apache2
export APACHE_PID_FILE=/tmp/apache2/apache2.pid
mkdir -p "$APACHE_RUN_DIR"

# --- PHP overrides (write only to /tmp; preserve defaults if envs are unset)
mkdir -p /tmp/php-conf.d
: > /tmp/php-conf.d/zz-runtime.ini
[ -n "${PHP_MEMORY_LIMIT:-}" ]        && printf 'memory_limit=%s\n'             "$PHP_MEMORY_LIMIT"        >> /tmp/php-conf.d/zz-runtime.ini
[ -n "${PHP_UPLOAD_MAX_FILESIZE:-}" ] && printf 'upload_max_filesize=%s\n'      "$PHP_UPLOAD_MAX_FILESIZE" >> /tmp/php-conf.d/zz-runtime.ini
[ -n "${PHP_POST_MAX_SIZE:-}" ]       && printf 'post_max_size=%s\n'            "$PHP_POST_MAX_SIZE"       >> /tmp/php-conf.d/zz-runtime.ini
[ -n "${PHP_MAX_EXECUTION_TIME:-}" ]  && printf 'max_execution_time=%s\n'       "$PHP_MAX_EXECUTION_TIME"  >> /tmp/php-conf.d/zz-runtime.ini
[ -n "${PHP_TZ:-}" ]                  && printf 'date.timezone=%s\n'            "$PHP_TZ"                  >> /tmp/php-conf.d/zz-runtime.ini
[ -n "${OPCACHE_ENABLE:-}" ]          && printf 'opcache.enable=%s\n'           "$OPCACHE_ENABLE"          >> /tmp/php-conf.d/zz-runtime.ini
[ -n "${OPCACHE_ENABLE_CLI:-}" ]      && printf 'opcache.enable_cli=%s\n'       "$OPCACHE_ENABLE_CLI"      >> /tmp/php-conf.d/zz-runtime.ini

# --- Build apache2ctl command (no writes to /etc at runtime)
set -- apache2ctl -D FOREGROUND
# Prefer -C (pre-config) to silence AH00558 early if provided
[ -n "${APACHE_SERVER_NAME:-}" ] && set -- "$@" -C "ServerName ${APACHE_SERVER_NAME}"

# --- Proxy awareness (requires 'a2enmod remoteip' during build)
if [ -n "${TRUSTED_PROXIES:-}" ]; then
  set -- "$@" -c "RemoteIPHeader X-Forwarded-For"
  # Accept comma or space separated
  for ip in $(echo "$TRUSTED_PROXIES" | tr ',' ' '); do
    [ -n "$ip" ] && set -- "$@" -c "RemoteIPTrustedProxy $ip"
  done
  # Mark HTTPS when behind TLS-terminating proxy
  set -- "$@" -c "SetEnvIfNoCase X-Forwarded-Proto https HTTPS=on"
fi

# --- Optional security headers (only if envs are set; requires 'a2enmod headers')
[ -n "${HSTS:-}" ]            && set -- "$@" -c "Header always set Strict-Transport-Security \"${HSTS}\" env=HTTPS"
[ -n "${CSP:-}" ]             && set -- "$@" -c "Header always set Content-Security-Policy \"${CSP}\""
[ -n "${CSP_REPORT_ONLY:-}" ] && set -- "$@" -c "Header always set Content-Security-Policy-Report-Only \"${CSP_REPORT_ONLY}\""

# --- App-writable dirs (avoid chown as we run non-root)
if [ -n "${APP_WRITABLE_DIRS:-}" ]; then
  for d in $APP_WRITABLE_DIRS; do
    mkdir -p "$d" || true
    chmod -R 750 "$d" || true
  done
fi

exec "$@" 
