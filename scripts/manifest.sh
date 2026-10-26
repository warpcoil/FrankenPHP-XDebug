#!/usr/bin/env bash
# manifest.sh <assets-dir> <frankenphp-version>  — prints manifest.json, removes the .info sidecars
set -euo pipefail
dir="$1" fp="$2"
items="[]"
for info in "$dir"/*.info; do
	[ -e "$info" ] || continue
	file="$(basename "${info%.info}")"
	sha="$(sha256sum "$dir/$file" | cut -d' ' -f1)"
	size="$(stat -c %s "$dir/$file")"
	items="$(jq -c --argjson add "$(jq -c --arg sha "$sha" --argjson size "$size" '. + {sha256: $sha, size: $size}' "$info")" '. + [$add]' <<<"$items")"
	rm -f "$info"
done
jq -n --arg fp "$fp" --arg built "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson assets "$items" \
	'{format: "quickspin-frankenphp", version: 1, frankenphp: $fp, built: $built, assets: ($assets | sort_by(.php, .platform))}'
