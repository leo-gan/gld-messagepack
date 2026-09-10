from std.collections import List

from runtime.error import DecodeError
from runtime.value import CK_BOOL, CK_INT, CK_NIL, CK_STR, CK_UINT, decode_value, encode_value
from wire.reader import WireReader
from wire.writer import WireWriter


def b1(a: Int) -> List[Byte]:
    var out = List[Byte]()
    out.append(Byte(a))
    return out^


def b2(a: Int, b: Int) -> List[Byte]:
    var out = List[Byte]()
    out.append(Byte(a))
    out.append(Byte(b))
    return out^


def b3(a: Int, b: Int, c: Int) -> List[Byte]:
    var out = List[Byte]()
    out.append(Byte(a))
    out.append(Byte(b))
    out.append(Byte(c))
    return out^


def b4(a: Int, b: Int, c: Int, d: Int) -> List[Byte]:
    var out = List[Byte]()
    out.append(Byte(a))
    out.append(Byte(b))
    out.append(Byte(c))
    out.append(Byte(d))
    return out^


def assert_eq(got: List[Byte], expect: List[Byte], label: String) raises:
    if len(got) != len(expect):
        raise Error(label + " length " + String(len(got)) + " != " + String(len(expect)))
    var i = 0
    while i < len(got):
        if Int(got[i]) != Int(expect[i]):
            raise Error(label + " mismatch at " + String(i))
        i += 1


def test_nil() raises:
    var w = WireWriter(capacity=8, exact=True)
    w.write_nil()
    var buf = w^.finish()
    assert_eq(buf, b1(0xC0), "nil")
    var v = decode_value(buf)
    if v.kind() != CK_NIL:
        raise Error("nil kind")
    var back = encode_value(v)
    assert_eq(back, buf, "nil roundtrip")


def test_bools() raises:
    var w = WireWriter(capacity=8, exact=True)
    w.write_bool(False)
    w.write_bool(True)
    var buf = w^.finish()
    assert_eq(buf, b2(0xC2, 0xC3), "bools")


def test_fixints() raises:
    var w = WireWriter(capacity=16, exact=True)
    w.write_int(Int64(0))
    w.write_int(Int64(127))
    w.write_int(Int64(-1))
    w.write_int(Int64(-32))
    var buf = w^.finish()
    assert_eq(buf, b4(0x00, 0x7F, 0xFF, 0xE0), "fixints")
    var r = WireReader(buf)
    if r.read_i64() != Int64(0):
        raise Error("0")
    if r.read_i64() != Int64(127):
        raise Error("127")
    if r.read_i64() != Int64(-1):
        raise Error("-1")
    if r.read_i64() != Int64(-32):
        raise Error("-32")


def test_uint8() raises:
    var w = WireWriter(capacity=8, exact=True)
    w.write_int(Int64(128))
    var buf = w^.finish()
    assert_eq(buf, b2(0xCC, 0x80), "uint8 128")
    var r = WireReader(buf)
    if r.read_i64() != Int64(128):
        raise Error("128")


def test_str() raises:
    var w = WireWriter(capacity=16, exact=True)
    w.write_str("hi")
    var buf = w^.finish()
    assert_eq(buf, b3(0xA2, 0x68, 0x69), "fixstr hi")
    var r = WireReader(buf)
    if r.read_str() != "hi":
        raise Error("str")
    var v = decode_value(buf)
    if v.as_str() != "hi":
        raise Error("value str")


def test_unused() raises:
    var buf = b1(0xC1)
    var raised = False
    try:
        _ = decode_value(buf)
    except e:
        raised = True
        if e.kind != DecodeError.KIND_UNUSED:
            raise Error("expected KIND_UNUSED")
    if not raised:
        raise Error("0xc1 must fail")


def main() raises:
    test_nil()
    test_bools()
    test_fixints()
    test_uint8()
    test_str()
    test_unused()
    print("test_atom ok")
