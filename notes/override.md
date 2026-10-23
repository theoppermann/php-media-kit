# Apache Overrides

- The container includes an extra include directory baked in:

  - IncludeOptional /opt/apache-extra/*.conf

With the stock virtual host, all .conf files you place in ./conf/apache-conf/ are loaded when Apache starts.
This allows you to add or override configuration without touching the base image.
If your project replaces `/etc/apache2/sites-enabled/000-default.conf`, you can
keep its settings directly in the replacement virtual host. To load additional
snippets, include selected files there, for example
`IncludeOptional /opt/apache-extra/50-uploads.conf`.

Use `IncludeOptional /opt/apache-extra/*.conf` inside a `<VirtualHost>` only when
the matched files contain configuration snippets valid in that context. If the
complete replacement virtual host is itself stored in `./conf/apache-conf/`,
that wildcard would include it too, causing an invalid nested virtual host.
Include selected snippets instead, or keep complete virtual-host files outside
the wildcard's directory.

### How it works

- All .conf files inside ./conf/apache-conf/ are loaded in alphabetical order.
- The mount is read_only, so the container cannot modify your files.
- You can create as many files as you like, and control the order with prefixes like 10-…, 50-…, 90-….

### Example 1: Gzip + cache headers
```
nano ./conf/apache-conf/50-cache.conf:
```
paste this
```
# Enable gzip compression
AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript

# Basic cache headers
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css "access plus 7 days"
    ExpiresByType application/javascript "access plus 7 days"
    ExpiresByType image/png "access plus 30 days"
    ExpiresByType image/jpeg "access plus 30 days"
    ExpiresDefault "access plus 1 day"
</IfModule>
```
Restart the container:
```
docker compose restart web
```

Test with:
```
curl -I http://localhost/health.php
```

You should see Content-Encoding: gzip and Expires headers.

### Example 2: Security headers (HSTS + CSP)
```
nano ./conf/apache-conf/80-security-extra.conf:
```
paste this:
```
# Force HTTPS (only enable if you are running behind TLS via Traefik/Nginx)
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

# Basic Content Security Policy
Header always set Content-Security-Policy "default-src 'self'; img-src 'self' data:; object-src 'none'"
```

Restart the container and test again:
```
docker compose restart web
curl -I http://localhost/health.php
```

You should now see:
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'; img-src 'self' data:; object-src 'none'
```


👉 This way you can easily add both performance optimizations and security policies without touching the base image.
