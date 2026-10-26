#!/usr/bin/env bash
# Copies the xdebug.so produced by static-php-cli into the output directory.
set -euo pipefail
dist="$1" out="$2"
so="$(find "$dist/buildroot" "$dist" -name 'xdebug.so' -type f 2>/dev/null | head -n1 || true)"
if [ -z "$so" ]; then
	echo "::error::xdebug.so was not produced. Contents of $dist/buildroot:"
	find "$dist/buildroot" -maxdepth 3 | head -n 200
	exit 1
fi
echo "found $so"
cp "$so" "$out/xdebug.so"
