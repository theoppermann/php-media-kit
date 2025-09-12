# Production vs Development

Configuration is controlled in docker-compose.yml.
By default, the stack runs in production mode for maximum security.

#### Service-level security

- read_only: true → locks the container root filesystem.
Keep this enabled in both prod and dev. Only relax it if a tool truly must write to the root FS (rare).

Mounts (defaults)

- ./www → /var/www/html read_only: true (code is protected).

  - Dev note: you still edit code on the host (your editor/IDE). Changes appear immediately in the container via the bind mount.

  - Switch to RW only if you need tools inside the container to write into the code tree (e.g., composer install writing vendor/ under www).

- ./data → /var/www/data (persistent, writable by www-data, served at /files/ with PHP disabled).

- /var/www/html/cache → tmpfs (in-memory, auto-cleared on restart).

- ./secrets → mounted as files (e.g., mail password).

- Uploads: Disabled by default. If your framework requires /var/www/html/uploads, see the short guide: notes/uploads.md.

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
