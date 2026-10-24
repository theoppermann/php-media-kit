# Verification

Run these commands from your project directory using the same Compose project
name and `-f` options as deployment. The examples assume the kit's `tests/`
directory is available there; adjust the input path if you keep it elsewhere.

## PHP diagnostic page

Copy the included [index.php](../index.php) to an unused filename under your
document root. With the default `./www` mount, for example:

```sh
cp -n index.php www/media-kit-check.php
```

Open `http://<server-ip>/media-kit-check.php`, including your published port if
needed. For a custom document root such as `www/public`, put the file there.
Remove the diagnostic copy when finished.

The page reports PHP, extensions and media tool versions. Use the tests below
to exercise actual AAF and codec operations.

## Python and AAF

Run the [AAF smoke test](../tests/python-aaf-smoke.py) as the configured web user:

```sh
docker compose exec -T web /opt/pyaaf2/venv/bin/python - < tests/python-aaf-smoke.py
```

It verifies UID 33, the installed venv and `aaf2` import, temporary-file access,
an AAF timeline roundtrip, and creation of a temporary venv with pip.
See [Python usage](python.md) for the runtime path and package updates.

## Media codecs

On the current build, run the [media smoke test](../tests/media-smoke.py):

```sh
docker compose exec -T web /opt/pyaaf2/venv/bin/python - --heif-encode < tests/media-smoke.py
```

This checks real HEIC/AVIF decoding and PNG thumbnails, HEIC/AVIF encoding
roundtrips, and FFmpeg HEVC/H.265 encoding and decoding.

For the previous and compatibility builds, omit `--heif-encode` to test their
existing decoder support and HEVC/H.265 encoding/decoding. Their original media
package choices and encoder availability are preserved.

The test downloads pinned, hash-checked libheif images into `/tmp` and removes
its temporary files afterwards. For offline tests, add
`--fixtures /path/in/container` pointing to `example.heic` and `example.avif`
from the sources recorded in the test script.
