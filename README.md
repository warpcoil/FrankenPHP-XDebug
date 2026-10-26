# FrankenPHP + Xdebug builds

[FrankenPHP](https://frankenphp.dev) binaries for **PHP 8.2, 8.3, 8.4 and 8.5**, each shipped with a matching **Xdebug** module, for:

| Platform | Built from | Xdebug |
|---|---|---|
| Linux x86_64 / aarch64 | FrankenPHP's own glibc static build (RHEL 8 builder, so it runs on glibc 2.28+) | `xdebug.so` built by static-php-cli as a shared extension |
| macOS arm64 / x86_64 | FrankenPHP's `build-static.sh` | `xdebug.so`, shared extension |
| Windows x86_64 | Official thread-safe PHP from windows.php.net + FrankenPHP's Windows build | Official thread-safe DLL from xdebug.org |

These builds are made for QuickSpin, a portable WordPress development environment, but they are ordinary FrankenPHP binaries.

## Release layout

Every release is tagged `v<FrankenPHP version>` and contains:

```
manifest.json                                  machine-readable index (QuickSpin reads this)
frankenphp-php8.3-linux-x86_64.tar.gz          frankenphp, xdebug.so, buildinfo.json
frankenphp-php8.3-linux-aarch64.tar.gz
frankenphp-php8.3-mac-arm64.tar.gz
frankenphp-php8.3-mac-x86_64.tar.gz
frankenphp-php8.3-windows-x86_64.zip           frankenphp.exe, PHP DLLs, ext\ (incl. php_xdebug.dll), php.exe
… the same for 8.2, 8.4, 8.5
```

The latest manifest is always at
`https://github.com/warpcoil/FrankenPHP-XDebug/releases/latest/download/manifest.json`:

```json
{
  "format": "quickspin-frankenphp",
  "version": 1,
  "frankenphp": "1.13.3",
  "built": "2026-10-26T04:40:00Z",
  "assets": [
    { "file": "frankenphp-php8.3-linux-x86_64.tar.gz", "php": "8.3", "platform": "linux-x86_64",
      "phpVersion": "8.3.30", "xdebug": "3.5.3", "zts": true, "sha256": "…", "size": 61234567 }
  ]
}
```

## Using a build

Xdebug is **not** enabled by default. Load it through an ini file in a scan directory:

```sh
mkdir -p ~/fp-ini
cat > ~/fp-ini/xdebug.ini <<EOF
zend_extension=/path/to/xdebug.so
xdebug.mode=debug
xdebug.start_with_request=trigger
EOF
PHP_INI_SCAN_DIR=~/fp-ini ./frankenphp php-server --root ./public
PHP_INI_SCAN_DIR=~/fp-ini ./frankenphp php-cli -r 'var_dump(extension_loaded("xdebug"));'
```

On Windows, use `zend_extension=C:/path/ext/php_xdebug.dll` and also `extension_dir` plus `extension=mysqli` (etc.), because the official PHP build ships its extensions as DLLs.

## How builds run

`.github/workflows/build.yml` runs:

- **Every Monday**: if FrankenPHP published a new release, it gets built. Newer PHP patch versions are picked up whenever a build runs.
- **Manually** (Actions → *Build FrankenPHP + Xdebug* → *Run workflow*): you can choose the FrankenPHP version, the PHP versions, and force a rebuild.

Every package is checked before it's published: the binary has to start, load `xdebug.so` / `php_xdebug.dll`, and have mysqli, gd, intl, mbstring, curl and zip. A combination that fails is skipped and the rest are still released. QuickSpin falls back to the official FrankenPHP build (PHP 8.5, no Xdebug) for anything missing.

| Script | Purpose |
|---|---|
| `scripts/patch-craft.sh` | Adds `shared-extensions: "xdebug"` to FrankenPHP's `craft.yml` |
| `scripts/collect-xdebug.sh` | Copies the built `xdebug.so` out of static-php-cli's build root |
| `scripts/package-unix.sh` | Checks that Xdebug loads, then creates the tarball and its metadata |
| `scripts/windows-php.ps1` | Downloads thread-safe PHP, the devel pack and Xdebug, and sets up the build environment |
| `scripts/package-windows.ps1` | Assembles the Windows zip and checks that Xdebug loads |
| `scripts/manifest.sh` | Writes `manifest.json` with checksums |

The build only needs the default `GITHUB_TOKEN`, so no secrets are required.

## Licences

FrankenPHP: MIT. PHP: PHP License v3.01. Xdebug: Xdebug License. These builds redistribute unmodified upstream sources.
