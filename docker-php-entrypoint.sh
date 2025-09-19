#!/bin/sh
set -e
umask 027

# Detect PHP X.Y and set writable INI scan dir
PHP_VERS="$(php -r 'printf("%d.%d", PHP_MAJOR_VERSION, PHP_MINOR_VERSION);')"
export PHP_INI_SCAN_DIR="/etc/php/${PHP_VERS}/apache2/conf.d:/tmp/php-conf.d"

# Apache runtime on tmpfs (RO-friendly)
export APACHE_RUN_DIR=/tmp/apache2
export APACHE_LOCK_DIR=/tmp/apache2
export APACHE_PID_FILE=/tmp/apache2/apache2.pid
mkdir -p "$APACHE_RUN_DIR" /var/run/apache2 /var/lock/apache2

# PHP overrides (write only to /tmp)
mkdir -p /tmp/php-conf.d
: > /tmp/php-conf.d/zz-runtime.ini

# --- Eksisterende nøgler ---
[ -n "${PHP_MEMORY_LIMIT:-}" ]        && printf 'memory_limit=%s\n'             "$PHP_MEMORY_LIMIT"        >> /tmp/php-conf.d/zz-runtime.ini
[ -n "${PHP_UPLOAD_MAX_FILESIZE:-}" ] && printf 'upload_max_filesize=%s\n'      "$PHP_UPLOAD_MAX_FILESIZE" >> /tmp/php-conf.d/zz-runtime.ini
[ -n "${PHP_POST_MAX_SIZE:-}" ]       && printf 'post_max_size=%s\n'            "$PHP_POST_MAX_SIZE"       >> /tmp/php-conf.d/zz-runtime.ini
[ -n "${PHP_MAX_EXECUTION_TIME:-}" ]  && printf 'max_execution_time=%s\n'       "$PHP_MAX_EXECUTION_TIME"  >> /tmp/php-conf.d/zz-runtime.ini
[ -n "${PHP_TZ:-}" ]                  && printf 'date.timezone=%s\n'            "$PHP_TZ"                  >> /tmp/php-conf.d/zz-runtime.ini
[ -n "${OPCACHE_ENABLE:-}" ]          && printf 'opcache.enable=%s\n'           "$OPCACHE_ENABLE"          >> /tmp/php-conf.d/zz-runtime.ini
[ -n "${OPCACHE_ENABLE_CLI:-}" ]      && printf 'opcache.enable_cli=%s\n'       "$OPCACHE_ENABLE_CLI"      >> /tmp/php-conf.d/zz-runtime.ini

# --- NYT: upload-/formular-relaterede nøgler ---
# Antal filer pr. request
[ -n "${PHP_MAX_FILE_UPLOADS:-}" ]    && printf 'max_file_uploads=%s\n'         "$PHP_MAX_FILE_UPLOADS"    >> /tmp/php-conf.d/zz-runtime.ini
# Mange formularfelter (checkboxes, arrays, …)
[ -n "${PHP_MAX_INPUT_VARS:-}" ]      && printf 'max_input_vars=%s\n'           "$PHP_MAX_INPUT_VARS"      >> /tmp/php-conf.d/zz-runtime.ini

# Kun på PHP >= 8.4: samlet antal multipart-dele (filer + felter)
PHP_ID="$(php -r 'echo PHP_VERSION_ID;')"   # ex: 80400 for 8.4.0
if [ "$PHP_ID" -ge 80400 ] && [ -n "${PHP_MAX_MULTIPART_BODY_PARTS:-}" ]; then
  printf 'max_multipart_body_parts=%s\n'    "$PHP_MAX_MULTIPART_BODY_PARTS"     >> /tmp/php-conf.d/zz-runtime.ini
fi

# Sessions to /tmp (Debian default path is RO)
mkdir -p /tmp/php-sessions
printf 'session.save_path=%s\n' '/tmp/php-sessions' >> /tmp/php-conf.d/zz-runtime.ini

# Build apache2ctl command (no writes to /etc at runtime)
set -- apache2ctl -D FOREGROUND
[ -n "${APACHE_SERVER_NAME:-}" ] && set -- "$@" -C "ServerName ${APACHE_SERVER_NAME}"

# Proxy awareness (requires a2enmod remoteip at build time)
if [ -n "${TRUSTED_PROXIES:-}" ]; then
  set -- "$@" -c "RemoteIPHeader X-Forwarded-For"
  for ip in $(echo "$TRUSTED_PROXIES" | tr ',' ' '); do
    [ -n "$ip" ] && set -- "$@" -c "RemoteIPTrustedProxy $ip"
  done
  set -- "$@" -c "SetEnvIfNoCase X-Forwarded-Proto https HTTPS=on"
fi

# Optional security headers (requires headers module)
[ -n "${HSTS:-}" ]            && set -- "$@" -c "Header always set Strict-Transport-Security \"${HSTS}\" env=HTTPS"
[ -n "${CSP:-}" ]             && set -- "$@" -c "Header always set Content-Security-Policy \"${CSP}\""
[ -n "${CSP_REPORT_ONLY:-}" ] && set -- "$@" -c "Header always set Content-Security-Policy-Report-Only \"${CSP_REPORT_ONLY}\""

# App-writable dirs (skip empties; no chown as non-root)
if [ -n "${APP_WRITABLE_DIRS:-}" ]; then
  for d in $APP_WRITABLE_DIRS; do
    [ -z "$d" ] && continue
    mkdir -p -- "$d" || true
    chmod -R 750 -- "$d" || true
  done
fi

exec "$@"
