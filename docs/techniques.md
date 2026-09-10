# Techniques

This page explains how mojo-messagepack encodes and decodes, why those
choices exist, and which ideas were measured and dropped. It is a description
of the shipped code, not a list of goals.

The library is written in Mojo. It does not call msgpack-c, mpack, rmp, or
MessagePack-CSharp. The algorithms below are ports of ideas from those
libraries into Mojo `List[Byte]`, word loads, and generated structs.

The timed path is generated-style `MsgpackDatum` encode and expected-order
decode. `MsgpackValue` (the dynamic tree) is not that path.

## Two paths

A generated struct implements `encoded_len`, `encode_to`, and `decode_from`.
Object keys are baked as byte literals in schema property order. The decoder
expects that order. Extra keys are skipped after a typed peek. Missing
required keys are an error.

`MsgpackValue` is an arena of nodes. It can hold any well-formed MessagePack
object. It allocates more and is not the speed target.

## Encode

### Pre-sized buffer

`WireWriter` allocates a `List[Byte]` whose **length** is the planned size,
not only its capacity. Each `write_byte` then stores at a cursor. If the
constructor only reserved capacity, every store resized from length 0.

`encode` of a generated type walks `encoded_len` first, then writes into that
buffer. The estimate can be slightly high. The writer trims to the cursor in
`finish`.

`encode_into` reuses a caller buffer. That is the same idea as
vmihailenco/msgpack `Encoder.Reset`.

### Shortest prefixes

Integers use disjoint ranges: `0…127` is one byte, `128…255` is uint 8, and
so on. Strings shorter than 32 bytes use fixstr. Arrays and maps of at most
15 items use the fix forms. That is the analog of CBOR preferred
serialization.

### Baked keys and memcpy

A generated map writes `"f_bool"` as one byte span (fixstr header plus
payload), not a per-byte string walk. `str` and `bin` payloads are a memcpy
after the header.

### Array and integer-key maps

When the schema says `x-msgpack-encoding: array`, the struct is an array in
property order and field names are not on the wire. When it says `intkeys`,
keys are integers. MessagePack-CSharp IntKey, Go `msgp`, and shamaton array
mode use the same idea. Default write stays a string-key map so the bytes
stay JSON-compatible.

## Decode

### 256-way first byte

Every object starts with one type byte. The reader branches on that byte
(`mpack` / `msgpack-c`). Unused `0xc1` is `KIND_UNUSED` on every path,
including `skip_value`.

### Expected order

Generated `decode_from` assumes schema property order. It peeks whether the
next key is a string (or an integer, for `intkeys`). A foreign key type is
skipped, not a hard type error. It does not build a hash map of keys.

That is glaze’s typed skip-DOM idea: the schema is known, so a tape or a
`MsgpackValue` object is extra work.

### Word-compare of short keys

A compact ASCII key of four or eight bytes can be compared as a little-endian
`UInt32` / `UInt64` after the fixstr header. Keys that do not fit that path
fall back to a byte compare.

### Floats on `"number"` fields

JSON Schema `"type": "number"` is Mojo `Float64` and is written as float 64.
Decode accepts any integer prefix plus float 32 and float 64
(`read_as_f64`). Python `msgpack.packb(1)` is an int. A generated
`f_float64` that only called `read_f64` would fail that input.

## Ideas that were measured and dropped

Wrapping msgpack-c was rejected. It would measure someone else's runtime and
break the from-scratch rule.

Always encoding structs as arrays is smaller and faster. It is not the
default because the suite records and most JSON-shaped APIs expect string
keys. The schema can still request array encoding.

Padding the input so SIMD can load past the end was not added. MessagePack
has no whitespace scan, so a structural index like simdjson stage-1 does not
apply.

Re-encoding a `MsgpackValue` to preserve overlong prefixes (identity mode)
stays out of v1.
