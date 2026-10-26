# Downloads the newest thread-safe PHP build for $env:PHP_MINOR, its devel pack and the
# matching thread-safe Xdebug DLL, then exports the variables the FrankenPHP build needs.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$minor = $env:PHP_MINOR
$ws = $env:GITHUB_WORKSPACE

$version = $null; $vs = $null; $base = $null
foreach ($b in @('https://downloads.php.net/~windows/releases/', 'https://downloads.php.net/~windows/releases/archives/')) {
  $html = (Invoke-WebRequest -Uri $b -UseBasicParsing).Content
  $found = [regex]::Matches($html, "php-($([regex]::Escape($minor))\.\d+)-Win32-(vs1[67])-x64\.zip") |
    ForEach-Object { [pscustomobject]@{ v = [version]$_.Groups[1].Value; vs = $_.Groups[2].Value } } |
    Sort-Object v | Select-Object -Last 1
  if ($found) { $version = $found.v.ToString(); $vs = $found.vs; $base = $b; break }
}
if (-not $version) { throw "No thread-safe Windows build of PHP $minor found" }
Write-Host "PHP $version ($vs) from $base"

$pkg = Join-Path $ws 'pkg'
Invoke-WebRequest "$base/php-$version-Win32-$vs-x64.zip" -OutFile "$env:TEMP\php.zip"
Expand-Archive "$env:TEMP\php.zip" -DestinationPath $pkg
Invoke-WebRequest "$base/php-devel-pack-$version-Win32-$vs-x64.zip" -OutFile "$env:TEMP\devel.zip"
Expand-Archive "$env:TEMP\devel.zip" -DestinationPath (Join-Path $ws 'php-devel')
$devel = Get-ChildItem (Join-Path $ws 'php-devel') -Directory | Select-Object -First 1 -ExpandProperty FullName

# Thread-safe Xdebug for this PHP minor (file names: php_xdebug-X.Y.Z-8.3-ts-vs16-x86_64.dll or ...-8.3-vs16-x86_64.dll)
$xdebug = $null
foreach ($page in @('https://xdebug.org/download', 'https://xdebug.org/download/historical')) {
  $html = (Invoke-WebRequest -Uri $page -UseBasicParsing).Content
  $m = [regex]::Matches($html, "php_xdebug-(\d+\.\d+\.\d+)-$([regex]::Escape($minor))-(?:ts-)?vs1[67]-x86_64\.dll") |
    ForEach-Object { [pscustomobject]@{ v = [version]$_.Groups[1].Value; f = $_.Value } } |
    Sort-Object v | Select-Object -Last 1
  if ($m) { $xdebug = $m; break }
}
if (-not $xdebug) { throw "No thread-safe Xdebug DLL found for PHP $minor" }
New-Item -ItemType Directory -Force (Join-Path $ws 'xdebug') | Out-Null
Invoke-WebRequest "https://xdebug.org/files/$($xdebug.f)" -OutFile (Join-Path $ws 'xdebug\php_xdebug.dll')
Write-Host "Xdebug $($xdebug.v) ($($xdebug.f))"

$vcpkg = Join-Path $ws 'frankenphp\vcpkg_installed\x64-windows'
$watcher = Join-Path $ws 'watcher'
"C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Tools\Llvm\bin" >> $env:GITHUB_PATH
"$vcpkg\bin" >> $env:GITHUB_PATH
$watcher >> $env:GITHUB_PATH
$pkg >> $env:GITHUB_PATH
"PHP_VERSION=$version" >> $env:GITHUB_ENV
"XDEBUG_VERSION=$($xdebug.v)" >> $env:GITHUB_ENV
"CGO_CFLAGS=-DFRANKENPHP_VERSION=$env:FRANKENPHP_VERSION -I$vcpkg\include -I$watcher -I$devel\include -I$devel\include\main -I$devel\include\TSRM -I$devel\include\Zend -I$devel\include\ext" >> $env:GITHUB_ENV
"CGO_LDFLAGS=-L$vcpkg\lib -lbrotlienc -L$watcher -llibwatcher-c -L$pkg -L$devel\lib -lphp8ts -lphp8embed" >> $env:GITHUB_ENV
