from std.time import perf_counter_ns

from msgpack import MsgpackDatum, decode, encode_into
from Document import Document
from DocumentItem import DocumentItem
from DocumentMeta import DocumentMeta
from Event import Event
from EventAttr import EventAttr
from Message import Message
from Strings import Strings
from Telemetry import Telemetry


def _fill_message() -> Message:
    var m = Message()
    m.f_bool = True
    m.f_int32 = Int64(1)
    m.f_int64 = Int64(17)
    m.f_float64 = 0.5
    m.f_string = String("abc")
    m.f_bool_2 = True
    m.f_int32_2 = Int64(9)
    m.f_string_2 = String("z")
    return m^


def _fill_telemetry() -> Telemetry:
    var t = Telemetry()
    var i = 0
    while i < 32:
        t.values.append(Float64(i) * 0.5)
        i += 1
    return t^


def _fill_strings() -> Strings:
    var s = Strings()
    var i = 0
    while i < 32:
        s.items.append(String("abcdefghij"))
        i += 1
    return s^


def _fill_document() -> Document:
    var d = Document()
    d.id = String("id-1")
    d.status = Int64(1)
    d.meta.region = String("us")
    d.meta.version = Int64(2)
    var i = 0
    while i < 4:
        var it = DocumentItem()
        it.sku = String("sku")
        it.qty = Int64(i)
        it.price_minor = Int64(100)
        d.items.append(it^)
        i += 1
    return d^


def _fill_event() -> Event:
    var e = Event()
    e.ts = Int64(1000)
    var i = 0
    while i < 4:
        var a = EventAttr()
        a.key = String("k")
        a.value = String("v")
        e.attrs.append(a^)
        i += 1
    return e^


def _bench[T: MsgpackDatum](name: String, value: T, iters: Int) raises:
    var dest = List[Byte]()
    var n = 0
    var i = 0
    while i < 80:
        n = encode_into(value, dest)
        i += 1
    var t0 = perf_counter_ns()
    i = 0
    while i < iters:
        n = encode_into(value, dest)
        i += 1
    var ser = Int(perf_counter_ns() - t0) // iters
    t0 = perf_counter_ns()
    i = 0
    while i < iters:
        _ = decode[T](dest[0:n])
        i += 1
    var des = Int(perf_counter_ns() - t0) // iters
    if ser < 1:
        ser = 1
    if des < 1:
        des = 1
    print(
        name,
        " ser_ns=",
        ser,
        " deser_ns=",
        des,
        " ops_ser=",
        1_000_000_000 // ser,
        " ops_des=",
        1_000_000_000 // des,
        " size=",
        n,
    )


def main() raises:
    var iters = 20000
    _bench("message", _fill_message(), iters)
    _bench("document", _fill_document(), iters)
    _bench("telemetry", _fill_telemetry(), 8000)
    _bench("strings", _fill_strings(), 8000)
    _bench("event", _fill_event(), iters)

