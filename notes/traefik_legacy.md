# Legacy Traefik notes

This page is retained as a legacy documentation link. No complete legacy
Traefik configuration is supplied by this repository.

For new deployments, use the current [HTTPS and reverse-proxy notes](traefik.md)
and configure the proxy for the project's domain, network and TLS setup. Existing
deployments can retain their own proxy configuration while selecting a current,
previous or compatibility [image build](builds.md). All five variants continue
to serve Apache HTTP on container port `8080`.
