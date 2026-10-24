# Third-Party Notices

The current default and retained image builds include software distributed under
its own licenses, including but not limited to:

- Debian GNU/Linux packages: package copyright information is normally under
  `/usr/share/doc/<package>/copyright` where retained in the image.
- PHP: [PHP licensing](https://www.php.net/license/).
- Apache HTTP Server: [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
- ImageMagick: [ImageMagick license](https://imagemagick.org/license/).
- Imagick PHP extension: [upstream license](https://github.com/Imagick/imagick/blob/master/LICENSE).
- FFmpeg and its enabled codecs/libraries: [FFmpeg licensing](https://ffmpeg.org/legal.html).
  The current source build enables GPL components; `ffmpeg -L` reports the
  license of the installed build.
- PHPMailer: [upstream license](https://github.com/PHPMailer/PHPMailer/blob/master/LICENSE),
  also supplied with its Composer vendor distribution or Debian package.
- Python 3: [Python license and third-party notices](https://docs.python.org/3/license.html).
- `pyaaf2`: MIT license; see its [PyPI metadata](https://pypi.org/project/pyaaf2/)
  and the installed distribution in `/opt/pyaaf2/venv`.

The current Trixie build compiles FFmpeg and ImageMagick from upstream source and
uses the official PHP/Python images. The previous and compatibility builds keep
their existing package sources; see [Build choices](notes/builds.md).

Optimized runtime images may omit package documentation, so license texts are
not guaranteed to be present under `/usr/share/doc/`. Consult the corresponding
upstream release and package sources when those files are absent. Dependencies
and enabled optional libraries also carry their own license terms.
