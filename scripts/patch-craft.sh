#!/usr/bin/env bash
# Adds Xdebug as a shared (loadable) extension to FrankenPHP's craft.yml.
# static-php-cli v3 merges `shared-extensions` into its build-shared option.
set -euo pipefail
craft="$1"
if grep -q '^shared-extensions:' "$craft"; then
	sed -i.bak -E 's/^shared-extensions:.*/shared-extensions: "xdebug"/' "$craft"
else
	# insert right after the extensions line
	awk '{print} /^extensions:/ && !done {print "shared-extensions: \"xdebug\""; done=1}' "$craft" >"$craft.new"
	mv "$craft.new" "$craft"
fi
rm -f "$craft.bak"
grep -nE '^(php-version|shared-extensions|sapi):' "$craft"
