#### Configuration

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
- Mail: Remember to use your own mail info and put passwords in secrets.
```
MAIL_HOST: "smtp.example.com"
MAIL_PORT: "587"
MAIL_SECURE: "tls"
MAIL_USER: "user@example.com"
MAIL_PASS_FILE: "/run/secrets/mail_pass"
```
