#!/usr/bin/env bash
# Symlinks every addon in this repo into the WoW Forever AddOns folder (macOS).
#   tools/install.sh [path-to-World-of-Warcraft]
set -euo pipefail
WOW_DIR="${1:-/Applications/World of Warcraft}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
ADDONS="$WOW_DIR/_forever_/Interface/AddOns"

if [ ! -d "$WOW_DIR/_forever_" ]; then
    echo "No _forever_ folder under $WOW_DIR." >&2
    echo "Find it in Battle.net: pick WoW Forever above Play, gear icon, Show in Finder, then rerun with that path." >&2
    exit 1
fi
mkdir -p "$ADDONS"

for dir in "$REPO"/*/; do
    name="$(basename "$dir")"
    [ -f "$dir/$name.toc" ] || continue
    [ "$name" = "HelloAzeroth" ] && continue
    target="$ADDONS/$name"
    if [ -L "$target" ]; then rm "$target"
    elif [ -e "$target" ]; then echo "skip $name: a real folder already exists at $target"; continue; fi
    ln -s "$dir" "$target"
    echo "linked $name -> $target"
done
echo
echo "Done. Restart the game client fully (not /reload) so it discovers the new folders."
