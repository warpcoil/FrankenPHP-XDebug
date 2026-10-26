#!/usr/bin/env bash
# package-unix.sh <output-dir> <binary-name> <php-minor> <platform-label>
# Verifies the binary loads xdebug.so, then writes dist-pkg/frankenphp-php<minor>-<platform>.tar.gz
set -euo pipefail
out="$1" bin="$2" php="$3" label="$4"
stage="$(mktemp -d)"
cp "$out/$bin" "$stage/frankenphp"
cp "$out/xdebug.so" "$stage/xdebug.so"
chmod +x "$stage/frankenphp"

ini="$(mktemp -d)"
printf 'zend_extension=%s\nxdebug.mode=debug\n' "$stage/xdebug.so" >"$ini/xdebug.ini"
# shellcheck disable=SC2016 # PHP code, not shell
info="$(PHP_INI_SCAN_DIR="$ini" "$stage/frankenphp" php-cli -r '
	foreach (["xdebug","mysqli","gd","intl","mbstring","curl","zip","opcache"] as $e) { if (!extension_loaded($e) && !extension_loaded("Zend ".ucfirst($e))) { fwrite(STDERR, "missing extension: $e\n"); exit(1); } }
	echo json_encode(["phpVersion" => PHP_VERSION, "xdebug" => phpversion("xdebug"), "zts" => (bool) PHP_ZTS]);')"
echo "verified: $info"
"$stage/frankenphp" version

name="frankenphp-php${php}-${label}.tar.gz"
mkdir -p dist-pkg
echo "$info" >"$stage/buildinfo.json"
tar -czf "dist-pkg/$name" -C "$stage" frankenphp xdebug.so buildinfo.json
echo "$info" | jq -c --arg file "$name" --arg php "$php" --arg platform "$label" '. + {file: $file, php: $php, platform: $platform}' >"dist-pkg/$name.info"
