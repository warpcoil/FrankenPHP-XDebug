# Assembles frankenphp.exe + the PHP distribution + Xdebug, checks that Xdebug loads, zips it.
$ErrorActionPreference = 'Stop'
$ws = $env:GITHUB_WORKSPACE
$pkg = Join-Path $ws 'pkg'
Copy-Item (Join-Path $ws 'frankenphp\caddy\frankenphp\frankenphp.exe') $pkg
Copy-Item (Join-Path $ws 'watcher\libwatcher-c.dll') $pkg
foreach ($dll in 'brotlienc.dll', 'brotlidec.dll', 'brotlicommon.dll', 'pthreadVC3.dll') {
  $p = Join-Path $ws "frankenphp\vcpkg_installed\x64-windows\bin\$dll"
  if (Test-Path $p) { Copy-Item $p $pkg }
}
Copy-Item (Join-Path $ws 'xdebug\php_xdebug.dll') (Join-Path $pkg 'ext\php_xdebug.dll')

# Verify: load the WordPress extensions and Xdebug the way QuickSpin will.
$ini = Join-Path $env:TEMP 'qs-ini'
New-Item -ItemType Directory -Force $ini | Out-Null
$ext = (Join-Path $pkg 'ext') -replace '\\', '/'
@"
extension_dir="$ext"
extension=curl
extension=gd
extension=intl
extension=mbstring
extension=mysqli
extension=openssl
extension=zip
zend_extension="$ext/php_xdebug.dll"
"@ | Set-Content -Encoding ascii (Join-Path $ini 'quickspin.ini')
$env:PHP_INI_SCAN_DIR = $ini
$code = 'foreach (["xdebug","mysqli","gd","intl","mbstring","curl","zip"] as $e) { if (!extension_loaded($e)) { fwrite(STDERR, "missing extension: $e\n"); exit(1); } } echo json_encode(["phpVersion" => PHP_VERSION, "xdebug" => phpversion("xdebug"), "zts" => (bool) PHP_ZTS]);'
$info = & (Join-Path $pkg 'frankenphp.exe') php-cli -r $code
if ($LASTEXITCODE -ne 0) { throw "Verification failed" }
Write-Host "verified: $info"
& (Join-Path $pkg 'frankenphp.exe') version

$info | Set-Content -Encoding ascii (Join-Path $pkg 'buildinfo.json')
New-Item -ItemType Directory -Force (Join-Path $ws 'dist-pkg') | Out-Null
$name = "frankenphp-php$($env:PHP_MINOR)-windows-x86_64.zip"
Compress-Archive -Path "$pkg\*" -DestinationPath (Join-Path $ws "dist-pkg\$name")
$meta = $info | ConvertFrom-Json
$meta | Add-Member file $name
$meta | Add-Member php $env:PHP_MINOR
$meta | Add-Member platform 'windows-x86_64'
($meta | ConvertTo-Json -Compress) | Set-Content -Encoding ascii (Join-Path $ws "dist-pkg\$name.info")
