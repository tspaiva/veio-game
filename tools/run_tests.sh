#!/usr/bin/env bash
# Runs the headless test suite. Set GODOT to the Godot 4 binary if it is not on PATH.
# Extra arguments are forwarded to the runner, e.g. --filter=interpreter
set -euo pipefail

GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."

# Import first so the global class cache (class_name) exists on fresh clones.
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . -s res://tests/framework/run_tests.gd -- "$@"
