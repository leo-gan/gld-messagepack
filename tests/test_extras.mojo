from msgpack import DecodeError, MsgpackValue, decode, encode, encode_into, make_int
from schema.parse import parse_schema_file
from schema.validate import VK_REQUIRED, VK_TYPE, is_valid, validate

from Blob import Blob
from Compact import Compact
from Message import Message
from Stamp import Stamp


def test_compact() raises:
    var c = Compact()
    c.a = True
    c.b = Int64(7)
    var buf = encode(c)
    if Int(buf[0]) != 0x92:
        raise Error("array header")
    var back = decode[Compact](buf)
    if (not back.a) or back.b != Int64(7):
        raise Error("compact roundtrip")


def test_blob() raises:
    var b = Blob()
    b.data.append(Byte(1))
    b.data.append(Byte(2))
    var buf = encode(b)
    var back = decode[Blob](buf)
    if len(back.data) != 2 or Int(back.data[1]) != 2:
        raise Error("blob")


def test_stamp() raises:
    var s = Stamp()
    s.when.sec = Int64(1)
    var buf = encode(s)
    var back = decode[Stamp](buf)
    if back.when.sec != Int64(1):
        raise Error("stamp")


def test_long_string() raises:
    var m = Message()
    var i = 0
    while i < 40:
        m.f_string += "a"
        i += 1
    var buf = encode(m)
    var back = decode[Message](buf)
    if back.f_string.byte_length() != 40:
        raise Error("long string")


def test_missing_required() raises:
    var empty = List[Byte]()
    empty.append(Byte(0x80))
    var raised = False
    try:
        _ = decode[Message](empty)
    except e:
        raised = True
        if e.kind != DecodeError.KIND_SCHEMA:
            raise Error("expected KIND_SCHEMA")
    if not raised:
        raise Error("missing required")


def test_validate() raises:
    var doc = parse_schema_file("testdata/schema/benchmark_v2.json")
    var m = Message()
    m.f_string = String("x")
    var buf = encode(m)
    var v = decode_value_safe(buf)
    if not is_valid(v, doc):
        raise Error("valid message")
    var bad = make_int(Int64(1))
    var r = validate(bad, doc)
    if r.code != VK_TYPE:
        raise Error("int is not Message")


def decode_value_safe(buf: List[Byte]) raises -> MsgpackValue:
    from runtime.value import decode_value

    return decode_value(buf)


def test_encode_into_prefix() raises:
    var m = Message()
    m.f_int64 = Int64(3)
    var dest = List[Byte]()
    var n = encode_into(m, dest)
    if n <= 0 or n > len(dest):
        raise Error("prefix")
    var back = decode[Message](dest[0:n])
    if back.f_int64 != Int64(3):
        raise Error("into")


def main() raises:
    test_compact()
    test_blob()
    test_stamp()
    test_long_string()
    test_missing_required()
    test_validate()
    test_encode_into_prefix()
    print("test_extras ok")
