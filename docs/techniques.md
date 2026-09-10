# Techniques

This page explains how mojo-messagepack encodes and decodes. It is a
description of the shipped code. Each section names the problem, why this
library uses a given method, and what you give up by using it.

The library is written in Mojo. It does not call msgpack-c, mpack, rmp, or
MessagePack-CSharp. The methods below are ports of ideas from those libraries
and from the sibling
[serializer-benchmark](https://github.com/leo-gan/GLD.SerializerBenchmark)
clients (C `mpack` / `msgpack-c`, Go `msgp` and shamaton array mode,
MessagePack-CSharp IntKey, glaze-style typed skip).

The timed path is a generated struct (`MsgpackDatum`) with `encode_into` and
`decode`. `MsgpackValue` (the dynamic tree) is not that path.

Numbers on this page come from the local `benches/microbench.mojo` on this
host. They are useful for a compile-test loop. They are not an official
cross-language ranking. There is no Mojo MessagePack row in
serializer-benchmark yet.

On the generated `Message` record, a 2026-09-10 pass moved encode from about
**84 ns to 65 ns** and decode from about **613 ns to 169 ns**. Decode is
more than twice as fast. Encode is about 29% faster. The remaining encode
gap is many small stores, not one large algorithm.

## Two paths

A **generated struct** is a Mojo type that the CLI `gld-msgpackgen-mojo`
writes from a JSON Schema. It has three methods:

| Method | Role |
| --- | --- |
| `encoded_len` | How many bytes the value will occupy |
| `encode_to` | Write those bytes into a `WireWriter` |
| `decode_from` | Read those bytes from a `WireReader` |

Object keys are known at generate time. The encoder writes them as constants.
The decoder expects the same key order that this library writes. Extra keys
are skipped. Missing required keys are an error.

**Problem this solves.** A general decoder does not know the next field. It
must read a key, look it up, then read a value. That lookup is a hash map or
a long `if` chain, and the key is often a heap `String`. A generated decoder
already knows the schema, so it can compare the next bytes to `"f_bool"` and
move on.

**Trade-off.** If another program writes the same fields in a different
order, the fast path fails and a slower generic loop runs. The bytes are
still accepted. You pay the fast-path probe, then the generic walk.

`MsgpackValue` is an **arena**: one list of nodes, plus side lists for
strings, raw bytes, and extensions. It can hold any well-formed MessagePack
object without a schema. It allocates more. It is the right tool for unknown
data. It is not the speed target.

## Encode

Encode means “turn a Mojo value into MessagePack bytes.”

### Pre-sized buffer

`WireWriter` holds a `List[Byte]` and a cursor `pos`. A store writes
`buf[pos]` and adds one to `pos`.

**Problem.** If the list’s length starts at 0, every store may grow the list.
Growing copies the old bytes to a larger allocation. Doing that once per
byte is much slower than writing into space that is already there.

**What we do.** `encode` calls `encoded_len` first, then constructs the
writer with that **length**, not only a reserved capacity. `encode_into`
reuses a caller list so a loop of encodes does not allocate a new list each
time. That is the same idea as Go `vmihailenco/msgpack` `Encoder.Reset` and
C `mpack_writer_init` with a caller buffer.

**Trade-off.** `encoded_len` walks the value twice (once to count, once to
write). For a small `Message` that extra walk is cheap next to an allocation.
`encode_into` skips the count when the destination is already large enough.
If the count is slightly high, `finish` trims the cursor. If it is low, a
mid-write `ensure` grows the list.

### Shortest prefixes

MessagePack has several ways to write the integer `1`: one byte `0x01`, or
`0xcc 0x01`, or a four-byte form, and so on.

**Problem.** A decoder must accept every legal form. An encoder that always
used the widest form would write larger messages. Larger messages take more
time to write and to read.

**What we do.** Default encode picks the shortest legal prefix. Integers
`0…127` are one byte. Strings shorter than 32 bytes use fixstr. Maps and
arrays of at most 15 items use the one-byte header. That is the analog of
CBOR “preferred serialization.”

**Trade-off.** The encoder has a chain of range tests. Those tests cost a
few comparisons. The suite records are small integers and short names, so
the first or second branch hits. An identity mode that preserved overlong
prefixes is not in v1.

### Baked keys and memcpy

A generated map must write the field name `"f_bool"` on the wire. In
MessagePack that is a type byte `0xa6` (fixstr of length 6) plus the six
ASCII bytes.

**Problem.** Calling `write_str("f_bool")` on every field walks a `String`,
computes a header, then copies. Doing that eight times per `Message` is
pure overhead: the name never changes.

**What we do.** The generator emits `write_fixstr("f_bool".as_bytes())` or,
for names of at most 7 bytes, `write_lit(UInt64(…), n)` which stores the
header and the name as one integer. Payload strings and `bin` values still
use `memcpy` after the header. C `mpack_write_cstr` and Go `msgp` do the
same for known keys: the name is data in the program, not something parsed
at run time.

**Trade-off.** The generated source contains magic integers. They are
correct only for shortest-form keys. A peer that wrote the same name as
`str 8` would not match the fast decode path (the generic path still
accepts it). `write_lit` must not `ensure(8)` when only 7 bytes remain in
an exact-size buffer: that would grow the list on every encode. The shipped
`write_lit` ensures `n` bytes and uses a byte loop if eight bytes would
run past the current length.

### Array and integer-key maps

MessagePack-CSharp’s fastest path writes structs as arrays or as maps whose
keys are `0, 1, 2, …`. Go `msgp` and shamaton `MarshalAsArray` do the same.
Field names disappear from the wire.

**Problem.** String keys are easy to debug and match JSON. They also waste
bytes and time: every record repeats `"f_float64"`.

**What we do.** Default write is a string-key map. A schema may set
`x-msgpack-encoding` to `array` or `intkeys`. Then generated code writes
an array in property order, or a map with integer keys.

**Trade-off.** Array encoding is smaller and faster. It is not
JSON-compatible and it is positional: a new field in the middle shifts
every later index. Integer keys need both sides to share the numbers. That
is why the default stays string keys.

### Unrolled multi-byte stores

Floats are eight IEEE 754 bytes after `0xcb`. A loop of eight shifts is
correct and short.

**Problem.** A tiny loop has a counter, a branch, and a shift on every
byte. For telemetry (32 floats) that loop is most of encode.

**What we do.** `write_f64` and `write_be` for 2, 4, and 8 bytes are
unrolled: eight assignments, no loop. `read_be` is unrolled the same way
on decode.

**Trade-off.** More source lines. The CPU prefers straight-line stores for
this width. We did not unroll 1-byte and 3-byte forms; they are rare on the
suite.

## Decode

Decode means “turn MessagePack bytes into a Mojo value.”

### 256-way first byte

Every MessagePack object starts with one type byte. `0xc2` is false. `0xa6`
is a 6-byte string. `0xc1` is unused and is always an error.

**Problem.** A decoder that does not look at that byte first must try
several parsers (“is this an int? a string?”). That is wasted work.

**What we do.** The reader branches on the first byte, the same way
`mpack` and `msgpack-c` do. `skip_value` uses the same table so it can
jump over an unknown field without building a value. `0xc1` is
`KIND_UNUSED` on every path.

**Trade-off.** The function is long. A computed goto or a 256-entry
function table would be even more direct; Mojo 1.0 does not give us that
cleanly, so we use `if` / `elif` on integer ranges (`0x00…0x7f` is
positive fixint).

### Expected-order keys, no `String` for the name

**Problem.** The old generated decoder did this for every field:

1. Read the key as a `String` (heap allocation).
2. Compare that string to `"f_bool"`, then `"f_int32"`, and so on.
3. Read the value.

Eight keys meant eight allocations before any useful field was stored. That
was most of the 613 ns `Message` decode.

**What we do.** After reading the map header, the decoder tries
`_decode_expected`. That method calls `try_eat_fixstr("f_bool".as_bytes())`,
which compares the next bytes to `0xa6` plus `f_bool` and advances the
cursor. No `String` is built. Then it reads the value. If any key is
missing or in another order, it rewinds and runs the generic loop (which
still allocates keys).

This is glaze’s typed skip-DOM idea, also used in the sibling mojo-json
client: the schema is known, so a tree or a hash map is extra work.

**Trade-off.** The fast path assumes this library’s encode order and
shortest string keys. Interop with Python `msgpack.packb` of a dict may
use a different key order. Then you pay a failed probe plus the generic
loop. The probe is a handful of byte compares, so that case is still
correct and only slightly slower than the old decoder.

### Why `strings` decode is still expensive

The `strings` suite record is 32 owned `String` values. Each one is a heap
allocation. Expected-order keys do not help those payloads: the keys are
few, the values are many.

**Trade-off.** A zero-copy view (`StringSpan` into the input) would avoid
those allocations. The public field type is still owned `String`, because
the caller can drop the input buffer. Views are a later item in DESIGN.md.

### Floats on `"number"` fields

JSON Schema `"type": "number"` is Mojo `Float64` and is **written** as
float 64 (`0xcb`).

**Problem.** Python `msgpack.packb(1)` writes an integer. A decoder that
only accepted `0xca` / `0xcb` would reject that input on `f_float64` and
on telemetry values.

**What we do.** Generated `Float64` fields call `read_as_f64`, which
accepts any integer prefix plus float 32 and float 64.

**Trade-off.** `read_as_f64` has more branches than `read_f64`. Suite
telemetry is all float 64 after our encoder, so those extra branches
rarely hit on the timed path. They exist for interop.

## Ideas that were measured and dropped

Each row was implemented, compiled, and timed on
`benches/microbench.mojo`. Only measured wins stayed.

| Idea | Source | Outcome |
| --- | --- | --- |
| Pre-size writer **length** | yyjson, glaze, mpack caller buffer | Kept. Reserve-only resized on every byte. |
| `encode_into` reuse | vmihailenco `Reset` | Kept. Timed encode path. |
| Baked `write_fixstr` / `write_lit` | Go `msgp`, mpack known keys | Kept. Small encode win. |
| Expected-order `try_eat_fixstr` | glaze, mojo-json | Kept. Largest decode win (613 ns → ~169 ns on `Message`). |
| Unrolled 2/4/8-byte I/O | msgpack-c / mpack stores | Kept. Helps telemetry floats. |
| `write_lit` `ensure(8)` always | guessed for u64 store | Grew an exact-size dest every encode. Now ensures `n` and falls back to bytes if 8 would run past the end. |
| Runtime u64 rebuild of a key on every `try_eat_fixstr` | mojo-json word compare | Slower than a 6–10 byte loop. Reverted. The compare is scalar. |
| Always encode structs as arrays | MessagePack-CSharp IntKey, shamaton | Faster and smaller. Not the default. Schema can request it. |
| Wrap msgpack-c | C bench client | Rejected. Would measure someone else's runtime. |
| Input NUL padding | simdjson padded input | MessagePack has no whitespace scan. Copy cost, little gain. Not added. |
| Identity encode (keep overlong prefixes) | CBOR identity | Out of v1. |

## What is still expensive

`strings` decode is about 2 µs for 32 heap `String`s. The key walk is not
the bound. EmberJson’s JSON path has the same allocation shape.

`encode` of `Message` is about 65 ns. That is many small stores (map
header, eight keys, eight values). There is no remaining 2× method that
keeps string-key maps and shortest prefixes. Array encoding would be the
next large cut, at the cost of wire compatibility.

A tape (classify the whole buffer, then copy) would help `strings` and
hurt `message`, where the schema is already known.

## How to read the local numbers

```bash
pixi run mojo run -I src -I tests/generated benches/microbench.mojo
```

The command prints nanoseconds per encode and decode, and the byte size.
Run it twice. The first run includes compile. Compare medians of later
runs on the same machine.

A faster encode that wrote wider integers would make size larger and could
make decode slower. The shortest-prefix writer is kept because size stayed
93 bytes for the local `Message` record.
