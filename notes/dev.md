# Production vs Development

Configuration is controlled in docker-compose.yml.
By default, the container root filesystem and the application code mount are read-only.
The current Trixie build is selected by default; use an explicit variant file to
retain the previous Debian PHP 8.4 build or another [build choice](builds.md).
The mounts and runtime user are shared across all five builds.

#### Service-level security

- read_only: true → locks the container root filesystem.
Keep this enabled in both prod and dev. Only relax it if a tool truly must write to the root FS (rare).

Mounts (defaults)

- ./www → /var/www/html read_only: true (code is protected).

  - Dev note: you still edit code on the host (your editor/IDE). Changes appear immediately in the container via the bind mount.

  - Switch to RW only if you need tools inside the container to write into the code tree (e.g., composer install writing vendor/ under www).

- ./data → /var/www/html/data (persistent, read-write). Set host directory ownership and permissions as shown in the [README](../README.md).

- /var/www/html/cache → tmpfs (in-memory, auto-cleared on restart).

- ./secrets/mail_pass.txt → /run/secrets/mail_pass (Compose secret file).

- Uploads: Disabled by default. If your framework requires /var/www/html/uploads, see the short guide: [Enable uploads dir](uploads.md)

### Data access and the legacy /files alias

With the stock virtual host, the document root is `/var/www/html`, so the
mounted data directory can be served directly at `/data/`. This mount does not
automatically disable PHP execution or restrict HTTP access.

Projects control access through their Apache configuration. For example, a
project can use `/var/www/html/public` as its document root while keeping data
at `/var/www/html/data`, outside that public directory. The application can then
serve private files after checking the user's access. When changing the document
root, also place the health endpoint under the selected document root.
See [Apache overrides](override.md) for configuration and replacement-vhost details.

The images also contain a legacy `/files/` alias pointing to `/var/www/data/`.
PHP execution is disabled for that separate directory. The default Compose file
does not mount `./data` there, so this alias neither exposes nor protects the
current `/var/www/html/data` mount.

### Python development and temporary files

All five builds provide `/opt/pyaaf2/venv/bin/python`, venv support and `pyaaf2`
(imported as `aaf2`). The environment is built into the image and lies outside
the code/data mounts. Running it does not require making the root filesystem or
the venv writable.

Use the existing `/tmp` tmpfs for temporary processing files or disposable
virtual environments. The web user (UID 33) can write there; those files are
discarded when the container stops. Save output that must persist to the
configured data mount. See [Python usage and the smoke test](../README.md#python-and-aaf-tools-all-builds).

The supplied `/tmp` tmpfs is mounted `noexec`. For a disposable venv there, use
`python3 -m venv --symlinks /tmp/my-venv` and invoke pip as
`/tmp/my-venv/bin/python -m pip`. The interpreter symlink points to Python in the
image; copied executables and scripts stored in `/tmp` cannot be executed directly.

### For most dev workflows you do not need this override—edit on the host, refresh the browser, done.
Optional dev override (only if in-container tools must write to ./www)

Create docker-compose.override.yml:
```
services:
  web:
    volumes:
      - type: bind
        source: ./www
        target: /var/www/html
        read_only: false   # only for dev when running composer/npm INSIDE the container
```

Compose loads `docker-compose.override.yml` automatically with the default
command. When using explicit `-f` files, include this override explicitly too:

```sh
docker compose -f docker-compose.yml -f docker-compose.trixie-debian.yml -f docker-compose.override.yml up -d --build
```

Use the same files and Compose project name for subsequent commands. For several
projects on one host, also override the fixed container name and published host
port as described in the [README](../README.md#notes).
