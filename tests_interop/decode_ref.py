#!/usr/bin/env python3
"""Oracle decode: stdin bytes → repr on stdout. timestamp=0, any map keys."""
from __future__ import annotations

import sys

import msgpack


def main() -> None:
    data = sys.stdin.buffer.read()
    val = msgpack.unpackb(data, raw=False, strict_map_key=False, timestamp=0)
    sys.stdout.write(repr(val) + "\n")


if __name__ == "__main__":
    main()
