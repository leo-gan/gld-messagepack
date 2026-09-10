#!/usr/bin/env bash
# Fail if generated Mojo is out of date.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
if [[ ! -f src/codegen/cli.mojo ]]; then
  echo "codegen CLI not present yet; skip"
  exit 0
fi
if [[ ! -f testdata/schema/benchmark_v2.json ]]; then
  echo "no benchmark schema yet; skip"
  exit 0
fi
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if command -v mojo >/dev/null 2>&1; then
  MOJO=(mojo)
else
  MOJO=(pixi run mojo)
fi
"${MOJO[@]}" run -I src src/codegen/cli.mojo -- --schema testdata/schema/benchmark_v2.json --out "$tmp"
if [[ -f tests/generated/Message.mojo ]]; then
  if ! diff -u tests/generated/Message.mojo "$tmp/Message.mojo"; then
    echo "generated Message.mojo is stale; run scripts/generate.sh" >&2
    exit 1
  fi
fi
if [[ -f testdata/schema/longlist.json ]]; then
  tmp2=$(mktemp -d)
  "${MOJO[@]}" run -I src src/codegen/cli.mojo -- --schema testdata/schema/longlist.json --out "$tmp2"
  if [[ -f tests/generated/LongList.mojo ]]; then
    if ! diff -u tests/generated/LongList.mojo "$tmp2/LongList.mojo"; then
      echo "generated LongList.mojo is stale; run scripts/generate.sh" >&2
      exit 1
    fi
  fi
fi
echo "generated sources match"
