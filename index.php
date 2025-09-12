<?php
header('Content-Type: text/plain');

// Basic environment info
echo "Environment checks\n";
echo "------------------\n";

// Debian version
echo "Debian: " . trim(file_get_contents('/etc/debian_version')) . "\n";

// PHP version
echo "PHP: " . PHP_VERSION . "\n";

// ImageMagick (via CLI)
exec("magick -version 2>&1", $imOutput, $imRet);
echo "ImageMagick: " . ($imRet === 0 ? $imOutput[0] : "not found") . "\n";

// php-imagick extension
if (extension_loaded('imagick')) {
    $imagick = new Imagick();
    echo "php-imagick: " . phpversion('imagick') . " (" . $imagick->getVersion()['versionString'] . ")\n";
} else {
    echo "php-imagick: not loaded\n";
}

// PDO drivers
if (extension_loaded('pdo')) {
    echo "PDO drivers: " . implode(', ', PDO::getAvailableDrivers()) . "\n";
} else {
    echo "PDO: not available\n";
}

// FFmpeg (CLI check only)
exec("ffmpeg -version 2>&1", $ffOutput, $ffRet);
echo "ffmpeg: " . ($ffRet === 0 ? $ffOutput[0] : "not found") . "\n";

// PHPMailer (class check)
echo "PHPMailer: " . (class_exists('PHPMailer\PHPMailer\PHPMailer') ? "available" : "not found") . "\n";

// ZIP extension
echo "ZIP extension: " . (extension_loaded('zip') ? "enabled" : "not enabled") . "\n";

// OPcache
echo "OPcache: " . (ini_get('opcache.enable') ? "enabled" : "disabled") . "\n";

// User
$uid = posix_geteuid();
$info = posix_getpwuid($uid);
echo "Running as: uid=$uid (" . $info['name'] . ")\n";

// Root FS check (very simple heuristic)
$testFile = '/test_write.lock';
if (@file_put_contents($testFile, 'test') === false) {
    echo "Root filesystem: read-only\n";
} else {
    echo "Root filesystem: writable\n";
    unlink($testFile);
}
