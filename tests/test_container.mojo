from std.collections import List

from runtime.value import CK_ARRAY, CK_MAP, decode_value, encode_value
from wire.reader import WireReader
from wire.writer import WireWriter


def assert_byte(got: Byte, expect: Int, label: String) raises:
    if Int(got) != expect:
        raise Error(label)


def test_array() raises:
    var w = WireWriter(capacity=16, exact=True)
    w.write_array_header(2)
    w.write_int(Int64(1))
    w.write_int(Int64(2))
    var buf = w^.finish()
    if Int(buf[0]) != 0x92:
        raise Error("fixarray 2")
    var v = decode_value(buf)
    if v.kind() != CK_ARRAY or v.count() != 2:
        raise Error("array count")
    if v.at(0).as_int() != Int64(1) or v.at(1).as_int() != Int64(2):
        raise Error("array items")
    var back = encode_value(v)
    if len(back) != len(buf):
        raise Error("array roundtrip len")


def test_map() raises:
    var w = WireWriter(capacity=16, exact=True)
    w.write_map_header(1)
    w.write_str("a")
    w.write_int(Int64(1))
    var buf = w^.finish()
    var v = decode_value(buf)
    if v.kind() != CK_MAP or v.count() != 1:
        raise Error("map count")
    if v.get("a").as_int() != Int64(1):
        raise Error("map get")


def test_skip() raises:
    var w = WireWriter(capacity=32, exact=True)
    w.write_map_header(1)
    w.write_str("x")
    w.write_array_header(2)
    w.write_int(Int64(9))
    w.write_str("z")
    var buf = w^.finish()
    var r = WireReader(buf)
    r.skip_value()
    if r.remaining() != 0:
        raise Error("skip leftover")


def main() raises:
    test_array()
    test_map()
    test_skip()
    print("test_container ok")
