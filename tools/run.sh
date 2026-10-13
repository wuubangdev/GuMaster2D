#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE="${GODOT_BIN:-$PROJECT_ROOT/.tools/godot/Godot_v4.7.2-stable_linux.x86_64}"
exec "$ENGINE" --path "$PROJECT_ROOT" "$@"
