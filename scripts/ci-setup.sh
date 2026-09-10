#!/usr/bin/env bash
# Install pixi + Mojo 1.0.0 for this repo.
# The Modular conda channel (https://conda.modular.com/max) may require a
# logged-in Modular / prefix.dev account. If `pixi install` fails with 401/403,
# export PREFIX_API_KEY (or the current Modular token) and retry.
# Never commit .env. PREFIX_API_KEY stays in CI secrets or a local .env.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if [[ -f "$root/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$root/.env"
  set +a
fi

if ! command -v pixi >/dev/null 2>&1; then
  echo "pixi not found; installing to ~/.pixi/bin" >&2
  curl -fsSL https://pixi.sh/install.sh | bash
  export PATH="${HOME}/.pixi/bin:${PATH}"
fi

if ! command -v pixi >/dev/null 2>&1; then
  echo "pixi install failed: pixi is still not on PATH" >&2
  echo "Add \$HOME/.pixi/bin to PATH and re-run." >&2
  exit 1
fi

echo "pixi: $(pixi --version)"
echo "channels: https://conda.modular.com/max , conda-forge"
echo "pin: mojo == 1.0.0"

if ! pixi install; then
  echo "pixi install failed." >&2
  echo "If the error is 401/403 on conda.modular.com, set PREFIX_API_KEY" >&2
  echo "(or the Modular token documented at https://mojolang.org/install/)" >&2
  echo "and re-run this script." >&2
  exit 1
fi

if ! pixi run mojo --version; then
  echo "mojo is not runnable after pixi install" >&2
  exit 1
fi

echo "ok: $(pixi run mojo --version)"
