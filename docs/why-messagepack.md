# Why MessagePack

[MessagePack](https://msgpack.org/) is a self-describing binary format. A
decoder does not need a schema to walk an object. Every object starts with one
type byte. Multi-byte integers and lengths are big-endian.

A schema language is optional. This library uses a [JSON Schema](https://json-schema.org/)
subset, plus a closed list of MessagePack extras, to generate Mojo structs.
Schema-free work uses `MsgpackValue`.

This library implements the
[2013 specification](https://github.com/msgpack/msgpack/blob/master/spec.md)
in Mojo. It does not call msgpack-c. Python `msgpack` is used only as a test
oracle.

The rest of this page is the subset of the spec that the library implements,
written for a reader who has not used MessagePack as a wire format before.
[Instructions](instructions.md) shows how to install and generate code.
[Examples](examples.md) shows the matching Mojo calls.

## Type bytes

| First byte | Format |
| --- | --- |
| `0x00`–`0x7f` | positive fixint (`0` … `127`) |
| `0x80`–`0x8f` | fixmap (`0` … `15` pairs) |
| `0x90`–`0x9f` | fixarray (`0` … `15` elements) |
| `0xa0`–`0xbf` | fixstr (`0` … `31` UTF-8 bytes) |
| `0xc0` | nil |
| `0xc1` | unused; always an error |
| `0xc2` / `0xc3` | false / true |
| `0xc4`–`0xc6` | bin 8 / 16 / 32 |
| `0xc7`–`0xc9` | ext 8 / 16 / 32 |
| `0xca` / `0xcb` | float 32 / float 64 |
| `0xcc`–`0xcf` | uint 8 / 16 / 32 / 64 |
| `0xd0`–`0xd3` | int 8 / 16 / 32 / 64 |
| `0xd4`–`0xd8` | fixext 1 / 2 / 4 / 8 / 16 |
| `0xd9`–`0xdb` | str 8 / 16 / 32 |
| `0xdc`–`0xdd` | array 16 / 32 |
| `0xde`–`0xdf` | map 16 / 32 |
| `0xe0`–`0xff` | negative fixint (`−32` … `−1`) |

Default encode writes the shortest legal prefix. Decode accepts any valid
prefix, including overlong integers.

## `str` versus `bin`

`str` is UTF-8. Invalid UTF-8 is an error. `bin` is raw bytes and is never
UTF-8 checked. A generated `String` field that sees `bin` is a type error.

## Maps and arrays

An array is an ordered list of objects.

A map is an ordered list of key/value pairs. Keys may be any MessagePack
object on `MsgpackValue`. Generated structs default to string keys. A schema
may request integer keys or array encoding (no field names on the wire).

Duplicate keys are well-formed. The last pair wins when a generated struct or
`MsgpackValue.get` looks up a key. Optional strict decode rejects duplicates.

## Extensions and timestamps

An extension is a signed type byte plus a payload. Type `-1` with a 4-, 8-,
or 12-byte payload is a
[timestamp](https://github.com/msgpack/msgpack/blob/master/spec.md#timestamp-extension-type).
Other extension types stay `MsgpackExt`.

## Streams

MessagePack objects may be concatenated. `StreamDecoder` yields or skips one
object at a time. Single-object `decode` still rejects leftover bytes.

## What this library does not implement

MessagePack-RPC, LZ4 wrappers around MessagePack, and GPU encode stay out of
v1. Those are not part of the 2013 type set.
