#!/usr/bin/env python3
"""Write testdata/golden/*.bin and *.hex from Python msgpack plus fail literals."""
from __future__ import annotations

from pathlib import Path

import msgpack

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "testdata" / "golden"


def write_bytes(name: str, data: bytes) -> None:
    GOLDEN.mkdir(parents=True, exist_ok=True)
    (GOLDEN / f"{name}.bin").write_bytes(data)
    (GOLDEN / f"{name}.bin.hex").write_text(data.hex() + "\n", encoding="utf-8")


def main() -> None:
    write_bytes("nil", msgpack.packb(None, use_bin_type=True))
    write_bytes("true", msgpack.packb(True, use_bin_type=True))
    write_bytes("false", msgpack.packb(False, use_bin_type=True))
    write_bytes("int_0", msgpack.packb(0, use_bin_type=True))
    write_bytes("int_127", msgpack.packb(127, use_bin_type=True))
    write_bytes("int_128", msgpack.packb(128, use_bin_type=True))
    write_bytes("int_neg1", msgpack.packb(-1, use_bin_type=True))
    write_bytes("int_150", msgpack.packb(150, use_bin_type=True))
    write_bytes("text_hi", msgpack.packb("hi", use_bin_type=True))
    write_bytes("bin_abc", msgpack.packb(b"abc", use_bin_type=True))
    write_bytes("array_1_2", msgpack.packb([1, 2], use_bin_type=True))
    write_bytes("map_a_1", msgpack.packb({"a": 1}, use_bin_type=True))
    write_bytes(
        "timestamp_1",
        msgpack.packb(msgpack.Timestamp(1, 0), use_bin_type=True),
    )
    write_bytes("float32_1", msgpack.packb(1.0, use_bin_type=True, use_single_float=True))
    # Fail-path literals. packb cannot emit these.
    write_bytes("unused_c1", bytes([0xC1]))
    write_bytes("truncated_uint8", bytes([0xCC]))
    write_bytes("bad_utf8_str", bytes([0xA1, 0xFF]))
    write_bytes("timestamp_len3", bytes([0xC7, 0x03, 0xFF, 0x00, 0x00, 0x00]))


if __name__ == "__main__":
    main()
