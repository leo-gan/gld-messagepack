from msgpack import decode_value, encode_value, make_int


def main() raises:
    var v = make_int(Int64(150))
    var buf = encode_value(v)
    var back = decode_value(buf)
    print(back.as_int())
