### Optional: Framework Uploads (/uploads)

This is an optional project setup for any of the five [build variants](builds.md).
It is not part of the default storage setup.

The default Compose file mounts `./data` at `/var/www/html/data`. With the stock
virtual host, that directory is inside the document root and can be served at
`/data/`. HTTP access and PHP execution there depend on the project's Apache
configuration.

The legacy `/files/` alias points to a separate directory, `/var/www/data/`, where
PHP execution is disabled. The default data mount does not use that directory.
See [Data access and the legacy /files alias](dev.md#data-access-and-the-legacy-files-alias)
for details and private-data setups using a project-specific document root.

Some frameworks and legacy apps instead expect a writable directory at
`/var/www/html/uploads`. With the stock virtual host, files there can be served
at `/uploads/`.

If your app requires this, enable it as follows:

1. Create the host storage directory and its mountpoint inside `./www`:

```sh
mkdir -p ./uploads ./www/uploads ./conf/apache-conf
sudo chown -R 33:33 ./uploads
sudo chmod -R 750 ./uploads
```

`./www/uploads` must exist before startup because `./www` is mounted read-only.

2. Add this bind mount to the existing `services.web.volumes` list in `docker-compose.yml`:

```yaml
services:
  web:
    volumes:
      - type: bind
        source: ./uploads
        target: /var/www/html/uploads
        read_only: false
```

Apply the mount change with `docker compose up -d`, including the selected build
override if you use an alternative variant.

#### Security note:

The legacy `/files/` policy does not apply to `/var/www/html/uploads`.
With the stock virtual host, files in `/uploads/` can be executed as PHP if uploaded.
If your framework only stores static files there (images, documents), you should harden it by disabling PHP execution:

Create `./conf/apache-conf/50-uploads.conf`:

```apache
<Directory /var/www/html/uploads>
  php_admin_flag engine off
  <FilesMatch "\.php$">
    Require all denied
  </FilesMatch>
</Directory>
```

The stock virtual host includes files from this override directory. If your
project replaces the virtual host, include this configuration in that vhost or
add the directory include described in [Apache overrides](override.md).
Restart Apache with `docker compose restart web` after changing the override.
Use the same variant `-f` options and Compose project name for these commands,
and adjust test URLs to your deployment's published port.

Choose the storage path your application expects. For private uploads, configure
the project's document root or HTTP access rules so files are served through the
application's access checks. Neither the default `/data/` mount nor an optional
`/uploads/` mount provides those checks automatically.

Python/AAF processing can use the shared `/opt/pyaaf2/venv/bin/python` and `/tmp`
for intermediate files. `/tmp` is temporary storage; save completed output in
the application's configured persistent mount.
