from msgpack import decode, encode

from Message import Message


def main() raises:
    var m = Message()
    m.f_bool = True
    m.f_int32 = Int64(1)
    m.f_int64 = Int64(150)
    m.f_float64 = 1.5
    m.f_string = String("hi")
    m.f_bool_2 = False
    m.f_int32_2 = Int64(2)
    m.f_string_2 = String("z")
    var buf = encode(m)
    var back = decode[Message](buf)
    if back.f_int64 != Int64(150) or back.f_string != "hi":
        raise Error("generated Message roundtrip")
    print("test_benchmark_v2 ok")
