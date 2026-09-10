#!/usr/bin/env bash
# Compare Mojo encode of atoms against Python msgpack.packb.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
py=(python3)
if command -v pixi >/dev/null 2>&1; then
  MOJO=(pixi run mojo)
else
  MOJO=(mojo)
fi

ref=$("${py[@]}" tests_interop/encode_ref.py int:150 | xxd -p -c 256)
mojo_hex=$("${MOJO[@]}" run -I src tests_interop/encode_mojo.mojo | tr -d '\n')
if [[ "$ref" != "$mojo_hex" ]]; then
  echo "int:150 mismatch ref=$ref mojo=$mojo_hex" >&2
  exit 1
fi
echo "interop ok"
