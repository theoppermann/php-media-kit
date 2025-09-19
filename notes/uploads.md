### Optional: Framework Uploads (/uploads)

By default this stack uses /data for safe, public media (served at /files/, with PHP disabled).
Some frameworks and legacy apps expect a writable folder inside the web root at /var/www/html/uploads.

If your app requires this, enable it as follows:
- Create host directory
```
mkdir -p ./uploads
sudo chown -R 33:33 ./uploads
sudo chmod -R 750 ./uploads
```
- Add to your docker-compose.yml:
```
  services:
  web:
    volumes:
      - type: bind
        source: ./uploads
        target: /var/www/html/uploads
```
#### ⚠️ Security note:

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

🔒 Recommendation:
Use /data whenever possible.
Only enable /uploads if your framework really requires it.

If you do enable it, also activate the uploads.override.conf unless your framework needs to run PHP code from /uploads (rare and unsafe).
