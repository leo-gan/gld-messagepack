# Examples

The snippets below assume `mojo run -I src` in a checkout, or an installed
`mojo-messagepack` package.

## Generated type

```mojo
from msgpack import encode, decode
from Message import Message

def main() raises:
    var m = Message()
    m.f_bool = True
    m.f_int64 = Int64(150)
    m.f_string = String("hi")
    var buf = encode(m)
    var back = decode[Message](buf)
    print(back.f_int64)
```

`encode_into` writes into a reused `List[Byte]` and returns the byte count.

## Dynamic value

```mojo
from msgpack import decode_value, encode_value, make_int

def main() raises:
    var v = make_int(Int64(150))
    var buf = encode_value(v)
    var back = decode_value(buf)
    print(back.as_int())
```

## Timestamp

```mojo
from msgpack import MsgpackTimestamp, WireWriter

def main() raises:
    var ts = MsgpackTimestamp(Int64(1), 0)
    var w = WireWriter(capacity=16, exact=True)
    ts.encode_to(w)
    var buf = w^.finish()
    print(len(buf))
```

Type `-1` with a 4-byte payload is unix seconds. The 8-byte and 12-byte
forms carry nanoseconds.

## Stream

```mojo
from msgpack import StreamDecoder, encode_stream, make_int

def main() raises:
    var items = List[MsgpackValue]()
    items.append(make_int(Int64(1)))
    items.append(make_int(Int64(2)))
    var buf = encode_stream(items)
    var dec = StreamDecoder(buf)
    while True:
        var nxt = dec.next_value()
        if not nxt:
            break
        print(nxt.value().as_int())
```
