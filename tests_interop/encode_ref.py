#!/usr/bin/env python3
"""Oracle encode: JSON-ish stdin description is not used. Pack argv values."""
from __future__ import annotations

import sys

import msgpack


def main() -> None:
    if len(sys.argv) < 2:
        sys.stderr.write("usage: encode_ref.py <nil|true|false|int:N|str:S>\n")
        sys.exit(2)
    spec = sys.argv[1]
    if spec == "nil":
        val = None
    elif spec == "true":
        val = True
    elif spec == "false":
        val = False
    elif spec.startswith("int:"):
        val = int(spec[4:])
    elif spec.startswith("str:"):
        val = spec[4:]
    else:
        sys.stderr.write("unknown spec\n")
        sys.exit(2)
    sys.stdout.buffer.write(msgpack.packb(val, use_bin_type=True))


if __name__ == "__main__":
    main()
