from std.collections import List

from runtime.stream import StreamDecoder, encode_stream
from runtime.value import MsgpackValue, make_int


def main() raises:
    var items = List[MsgpackValue]()
    items.append(make_int(Int64(1)))
    items.append(make_int(Int64(2)))
    var buf = encode_stream(items)
    var dec = StreamDecoder(buf)
    var a = dec.next_value()
    var b = dec.next_value()
    var c = dec.next_value()
    if not a or not b or c:
        raise Error("stream count")
    if a.value().as_int() != Int64(1) or b.value().as_int() != Int64(2):
        raise Error("stream values")
    print("test_stream ok")
