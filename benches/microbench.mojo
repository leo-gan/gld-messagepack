from std.time import perf_counter_ns

from msgpack import decode, encode_into
from Message import Message


def _fill_message(i: Int) -> Message:
    var m = Message()
    m.f_bool = (i % 2) == 0
    m.f_int32 = Int64(i)
    m.f_int64 = Int64(i * 17)
    m.f_float64 = Float64(i) * 0.5
    m.f_string = String("abc")
    m.f_bool_2 = True
    m.f_int32_2 = Int64(9)
    m.f_string_2 = String("z")
    return m^


def main() raises:
    var m = _fill_message(1)
    var dest = List[Byte]()
    var i = 0
    while i < 50:
        _ = encode_into(m, dest)
        i += 1
    var iters = 20000
    var t0 = perf_counter_ns()
    i = 0
    while i < iters:
        _ = encode_into(m, dest)
        i += 1
    var ser = Int(perf_counter_ns() - t0) // iters
    t0 = perf_counter_ns()
    i = 0
    while i < iters:
        _ = decode[Message](dest)
        i += 1
    var des = Int(perf_counter_ns() - t0) // iters
    print(
        "message n=1 ser_ns=",
        ser,
        " deser_ns=",
        des,
        " ops_ser=",
        1_000_000_000 // ser,
        " ops_des=",
        1_000_000_000 // des,
    )
