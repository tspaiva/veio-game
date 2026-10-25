#!/usr/bin/env bash
# Exports the web build to build/web. Requires the Godot web export templates
# (web_nothreads_*) for the pinned version. Set GODOT if it is not on PATH.
set -euo pipefail

GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."

mkdir -p build/web
# Keep Godot from importing (and re-exporting) its own build output.
touch build/.gdignore
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
test -f build/web/index.wasm
