# Python and AAF tools

All five builds include Python 3, venv support and the latest compatible stable
`pyaaf2` release available when the image's installation step runs. Import the
library as `aaf2`.

## Usage

Use `/opt/pyaaf2/venv/bin/python` directly; activation is unnecessary. For example,
run from your project directory with the same Compose project and `-f` options
used for deployment:

```sh
docker compose exec -T web /opt/pyaaf2/venv/bin/python -c "import aaf2; from importlib.metadata import version; print(version('pyaaf2'))"
```

The venv is installed during the image build, outside the code and data mounts.
It is root-owned and readable/executable by the web user (UID 33), including
with a read-only root filesystem. No packages are installed at container startup.

Temporary files belong in `/tmp`, which is writable tmpfs and is cleared when
the container stops. Save persistent output in your project's data mount.

## Updates and verification

The current default uses upstream stable Python; the retained builds use their
Debian Python packages. See [build choices](builds.md) for details.

`pyaaf2` is not pinned. Docker can reuse its cached installation layer; rebuild
with `--no-cache --pull` and recreate the container to refresh installed releases.

See [Python and AAF verification](testing.md#python-and-aaf) for the smoke test.
