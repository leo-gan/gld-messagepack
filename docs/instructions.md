# Instructions

If you have not used MessagePack as a wire format before, start with
[Why MessagePack](why-messagepack.md). That page explains type bytes, `str`
versus `bin`, maps, extensions, timestamps, and streams.
[Techniques](techniques.md) explains how encode and decode are implemented.

## Install Mojo 1.0.0

```bash
git clone https://github.com/leo-gan/gld-messagepack.git
cd gld-messagepack
pixi install
pixi run test
```

If `pixi install` fails with 401 on `conda.modular.com`, set `PREFIX_API_KEY`
in a local `.env` (never commit that file) and run `scripts/ci-setup.sh`.

After a conda install from prefix.dev:

```bash
pixi add --channel https://prefix.dev/leo-gan/leo-gan mojo-messagepack
```

That installs `msgpack.mojoc` (plus `wire` / `runtime` / `schema`) and
`gld-msgpackgen-mojo`.

## Generate Mojo from JSON Schema

Write a JSON Schema document that uses the v1 subset (`type`, `properties`,
`required`, `items`, local `$ref`, `$defs`, `enum`, `const`, two-branch null
unions, named-object `oneOf` / `anyOf`) plus the MessagePack extras
(`type: bytes`, `type: extension`, `x-msgpack-timestamp`,
`x-msgpack-encoding`, `x-msgpack-key`). Then run the generator. After a conda
install the command is `gld-msgpackgen-mojo`. In a checkout:

```bash
pixi run mojo run -I src src/codegen/cli.mojo -- \
  --schema testdata/schema/benchmark_v2.json --out tests/generated
```

`pixi run generate` rebuilds the in-tree types from every file under
`testdata/schema/`.

A property that is not in `required` becomes `Optional[T]`. A two-branch type
array `{T, null}` also becomes `Optional[T]`. Missing keys and MessagePack
`nil` both become `None`.

## Encode and decode

```mojo
from msgpack import encode, decode
from Message import Message

var m = Message()
m.f_int64 = Int64(150)
var buf = encode(m)
var m2 = decode[Message](buf)
```

`from msgpack import …` resolves with `mojo run -I src` in a checkout, or from
`msgpack.mojoc` after the package is installed.

Schema-free values use `MsgpackValue`:

```mojo
from msgpack import decode_value, encode_value

var v = decode_value(buf)
var again = encode_value(v)
```

Concatenated objects use `StreamDecoder.next_value` and `skip`.
