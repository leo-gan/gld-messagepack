#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
if command -v pixi >/dev/null 2>&1; then
  pixi run mojo run -I src -I tests/generated benches/microbench.mojo
else
  mojo run -I src -I tests/generated benches/microbench.mojo
fi
