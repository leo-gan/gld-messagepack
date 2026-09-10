# Test data

Files under `testdata/` are ordinary unit and interop material. They are not a
shared external suite and they are not a product schema.

| Tree | Why it exists |
| --- | --- |
| `testdata/schema/` | JSON Schema documents the generator and parser tests read |
| `testdata/golden/` | Oracle byte vectors plus `.hex` sidecars, and literal fail bytes |

## Schemas

| File | Why |
| --- | --- |
| `benchmark_v2.json` | `Message`, `Document`, `Telemetry`, and the other v2 shapes |
| `longlist.json` | Recursive optional record |
| `keywords.json` | Mojo keyword identifiers |
| `union.json` | Tagged union of named objects (`Cat` / `Dog`) |
| `optional.json` | Missing key versus `nil` versus `{T, null}` |
| `enum_const.json` | `enum` and `const` |
| `bytes.json` | `type: bytes` → `bin` |
| `timestamp.json` | `x-msgpack-timestamp` |
| `ext.json` | `type: extension` |
| `array_encoding.json` | `x-msgpack-encoding: array` |
| `intkeys.json` | `x-msgpack-encoding: intkeys` |

The v2 field names follow the gld-json DESIGN / bench `data.mojo` records.
They are not a copy of every sibling library's shipped testdata.

## Golden vectors

Success goldens come from Python `msgpack.packb(..., use_bin_type=True)` via
`scripts/gen_golden.py`. Fail-path goldens (`0xc1`, truncated headers,
invalid UTF-8 `str`, timestamp length 3) are literal bytes. The script writes
those literals; do not hand-edit the files it owns.

Unpack uses default `timestamp=0` so type `-1` stays `msgpack.Timestamp`.
Integer-key maps use `strict_map_key=False`.

## Derived files

`tests/generated/` is the output of `gld-msgpackgen-mojo`.
`scripts/check-generated.sh` fails if those files drift.
