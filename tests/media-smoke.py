"""Run as www-data using /opt/pyaaf2/venv/bin/python, including from stdin.

    /opt/pyaaf2/venv/bin/python - [--heif-encode] < tests/media-smoke.py

Use --fixtures DIRECTORY for offline tests with example.heic and example.avif.
The original builds need decoders; --heif-encode also requires both encoders.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import urllib.request


FIXTURE_BASE = (
    "https://raw.githubusercontent.com/strukturag/libheif/"
    "364905fc9841bdda229e0ae2c5fda13b5fc98d1a/examples/"
)
FIXTURES = {
    "example.heic": "7f8b363e4936c0666a25f64f3a92fda10bd8e5453be4592530b65a55dd98f3f2",
    "example.avif": "54a0dc31d02b6f5d9d4b66027d4787861b7af15ffd8fab8eab963d10c5411469",
}

PHP_CHECK = r'''
function check($condition, $message) {
    if (!$condition) { throw new RuntimeException($message); }
}
$checks = [];
foreach ([[$argv[1], 'HEIC', 1280, 854], [$argv[2], 'AVIF', 800, 533]] as $fixture) {
    [$path, $format, $width, $height] = $fixture;
    $image = new Imagick($path);
    $image->setIteratorIndex(0);
    // ImageMagick 6 reports AVIF through its HEIC coder. The fixture hash
    // identifies the actual input format; both names are valid decoder labels.
    check(in_array($image->getImageFormat(), [$format, 'HEIC', 'HEIF'], true),
        "$format decoder family not detected");
    check($image->getImageWidth() === $width && $image->getImageHeight() === $height,
        "$format fixture dimensions changed");
    $thumbnail = $image->getImage();
    $thumbnail->thumbnailImage(64, 64, true);
    $thumbnail->setImageFormat('PNG');
    $png = new Imagick();
    $png->readImageBlob($thumbnail->getImageBlob());
    check($png->getImageFormat() === 'PNG' && $png->getImageWidth() > 0
        && $png->getImageWidth() <= 64 && $png->getImageHeight() > 0
        && $png->getImageHeight() <= 64, "$format PNG thumbnail failed");
    $checks[] = strtolower($format) . '-decode-png-thumbnail';
    $png->clear(); $thumbnail->clear(); $image->clear();
}
if ($argv[3] === '1') {
    foreach (['HEIC', 'AVIF'] as $format) {
        $image = new Imagick();
        $image->newImage(64, 64, new ImagickPixel('white'));
        $image->setImageDepth(8);
        $image->setImageFormat($format);
        $blob = $image->getImageBlob();
        check(strlen($blob) > 0, "$format encoding returned an empty image");
        $header = unpack('Nsize/a4type/a4major/Nminor', substr($blob, 0, 16));
        check($header['type'] === 'ftyp' && $header['size'] >= 16
            && $header['size'] <= strlen($blob), "$format file-type box missing");
        $brands = array_merge([$header['major']],
            str_split(substr($blob, 16, $header['size'] - 16), 4));
        $expectedBrands = $format === 'AVIF' ? ['avif', 'avis']
            : ['heic', 'heix', 'hevc', 'hevx', 'heim', 'heis', 'hevm', 'hevs'];
        check(count(array_intersect($brands, $expectedBrands)) > 0,
            "$format encoding has the wrong file-type brand");
        $decoded = new Imagick();
        $decoded->readImageBlob($blob);
        check(in_array($decoded->getImageFormat(), [$format, 'HEIC', 'HEIF'], true)
            && $decoded->getImageWidth() === 64
            && $decoded->getImageHeight() === 64, "$format encoding roundtrip failed");
        $checks[] = strtolower($format) . '-encode-decode';
        $decoded->clear(); $image->clear();
    }
}
echo json_encode(['php' => PHP_VERSION, 'imagick' => phpversion('imagick'),
    'imagemagick' => Imagick::getVersion()['versionString'], 'checks' => $checks],
    JSON_THROW_ON_ERROR);
'''


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def command(arguments):
    try:
        result = subprocess.run(arguments, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(
            f"Command timed out: {arguments!r}\n{error.stdout or ''}{error.stderr or ''}"
        ) from error
    require(result.returncode == 0,
            f"Command failed ({result.returncode}): {arguments!r}\n"
            f"{result.stdout}{result.stderr}")
    return result.stdout.strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--heif-encode', action='store_true')
    parser.add_argument('--fixtures', type=Path)
    args = parser.parse_args()
    require(os.geteuid() == 33, 'Run this test as the web user (UID 33)')
    require(Path(sys.prefix) == Path('/opt/pyaaf2/venv'),
            'Use /opt/pyaaf2/venv/bin/python')

    # Only data lives in /tmp, so the test works with a noexec tmpfs.
    with tempfile.TemporaryDirectory(prefix='media-smoke-', dir='/tmp') as tmp:
        workspace = Path(tmp)
        fixtures = []
        for name, expected_hash in FIXTURES.items():
            if args.fixtures:
                path = args.fixtures / name
            else:
                path = workspace / name
                with urllib.request.urlopen(FIXTURE_BASE + name, timeout=60) as response:
                    path.write_bytes(response.read())
            require(hashlib.sha256(path.read_bytes()).hexdigest() == expected_hash,
                    f'Fixture SHA256 mismatch: {path}')
            fixtures.append(str(path))

        result = json.loads(command([
            'php', '-d', 'display_errors=stderr', '-r', PHP_CHECK, '--',
            *fixtures, '1' if args.heif_encode else '0',
        ]))
        result['ffmpeg'] = command(['ffmpeg', '-version']).splitlines()[0]
        video = str(workspace / 'test.hevc')
        command([
            'ffmpeg', '-hide_banner', '-loglevel', 'error', '-nostdin', '-y',
            '-f', 'lavfi', '-i', 'color=c=white:s=64x64:r=1', '-frames:v', '2',
            '-an', '-c:v', 'libx265', '-pix_fmt', 'yuv420p', '-x265-params',
            'pools=1:frame-threads=1:log-level=error', '-f', 'hevc', video,
        ])
        decoded = command([
            'ffmpeg', '-hide_banner', '-loglevel', 'error', '-nostdin', '-xerror',
            '-c:v', 'hevc', '-i', video, '-progress', 'pipe:1', '-f', 'null', '-',
        ])
        require('frame=2' in decoded.splitlines() and 'progress=end' in decoded.splitlines(),
                f'HEVC decoder did not complete two frames:\n{decoded}')
        result['checks'].append('hevc-libx265-encode-decode-two-frames')
        result.update(status='ok', uid=os.geteuid(), heif_encode=args.heif_encode,
                      offline_fixtures=args.fixtures is not None, tmp='/tmp')
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
