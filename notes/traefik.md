# HTTPS and reverse-proxy notes

All five build variants run Apache over HTTP on container port `8080`. HTTPS can
terminate at Traefik or another reverse proxy; choosing a PHP/media build does
not change that upstream port or the application's data mounts.

For a project-specific proxy deployment:

1. Connect the proxy and web container through the network selected by your
   deployment, and route requests to the web service on port `8080`.
2. Configure the domain, TLS router, certificate resolver and DNS in the proxy's
   deployment. For Traefik's Docker provider, explicitly set the service's
   `loadbalancer.server.port` to `8080`; see the
   [official Docker routing documentation](https://doc.traefik.io/traefik/reference/routing-configuration/other-providers/docker/).
3. Set `TRUSTED_PROXIES` in the web service to your actual proxy addresses or
   networks when using forwarded client-IP information. See [Runtime configuration](conf.md).
4. Replace the base Compose host-port mapping and fixed `container_name` as
   needed. Distinct Compose project names do not remove those fixed-value
   collisions; see [Multiple-project notes](dev.md#multiple-projects).

The container health check continues to use
`http://localhost:8080/health.php` internally. Keep that endpoint under your
selected document root even when public requests use HTTPS.

This repository does not supply a complete Traefik deployment or certificate
configuration. Keep those settings in the project's own Compose/proxy
configuration, using the same selected build files and project name for later
Compose commands.
