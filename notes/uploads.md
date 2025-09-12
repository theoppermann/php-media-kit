### ⚠️ Security note:

By default, files in /uploads can be executed as PHP if uploaded.
If your framework only stores static files there (images, documents), you should harden it by disabling PHP execution:

- Create an override file:

apache-conf/uploads.override.conf
```
<Directory /var/www/html/uploads>
  php_admin_flag engine off
  <FilesMatch "\.php$">
    Require all denied
  </FilesMatch>
</Directory>
```

- In docker-compose.yml, locate the existing commented block:
```
# - type: bind
#   source: ./apache-conf/uploads.override.conf
#   target: /etc/apache2/conf-enabled/99-uploads-override.conf
#   read_only: true
```
Uncomment it to activate the override.

🔒 Recommendation:
Use /data whenever possible.
Only enable /uploads if your framework really requires it.

If you do enable it, also activate the uploads.override.conf unless your framework needs to run PHP code from /uploads (rare and unsafe).
