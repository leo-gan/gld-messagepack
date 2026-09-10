from runtime.error import DecodeError
from runtime.timestamp import MsgpackTimestamp
from runtime.value import CK_TIMESTAMP, decode_value
from wire.reader import WireReader
from wire.writer import WireWriter


def test_ts32() raises:
    var ts = MsgpackTimestamp(Int64(1), 0)
    var w = WireWriter(capacity=16, exact=True)
    ts.encode_to(w)
    var buf = w^.finish()
    if len(buf) != 6:
        raise Error("ts32 len")
    if Int(buf[0]) != 0xD6 or Int(buf[1]) != 0xFF:
        raise Error("ts32 header")
    var r = WireReader(buf)
    var pair = r.read_timestamp()
    if pair[0] != Int64(1) or pair[1] != 0:
        raise Error("ts32 value")
    var v = decode_value(buf)
    if v.kind() != CK_TIMESTAMP:
        raise Error("ts kind")
    if v.as_timestamp().sec != Int64(1):
        raise Error("ts as")


def test_bad_len() raises:
    var buf = List[Byte]()
    buf.append(Byte(0xC7))
    buf.append(Byte(0x03))
    buf.append(Byte(0xFF))
    buf.append(Byte(0x00))
    buf.append(Byte(0x00))
    buf.append(Byte(0x00))
    var raised = False
    try:
        _ = decode_value(buf)
    except e:
        raised = True
        if e.kind != DecodeError.KIND_EXT:
            raise Error("expected KIND_EXT")
    if not raised:
        raise Error("len3 must fail")


def main() raises:
    test_ts32()
    test_bad_len()
    print("test_timestamp ok")
