from runtime.value import encode_value, make_int


def hex_byte(n: Int) -> String:
    var digits = "0123456789abcdef"
    var hi = n >> 4
    var lo = n & 15
    return String(digits[byte=hi]) + String(digits[byte=lo])


def main() raises:
    var buf = encode_value(make_int(Int64(150)))
    var i = 0
    while i < len(buf):
        print(hex_byte(Int(buf[i])), end="")
        i += 1
    print("")
