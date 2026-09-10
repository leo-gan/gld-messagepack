from std.collections import List, Optional, Span

from msgpack import (
    Box,
    DecodeError,
    EncodeOptions,
    MsgpackDatum,
    MsgpackExt,
    MsgpackTimestamp,
    WireReader,
    WireWriter,
    encoded_array_header_len,
    encoded_bin_len,
    encoded_ext_len,
    encoded_f64_len,
    encoded_int_len,
    encoded_map_header_len,
    encoded_str_len,
)

struct LongList(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var value: Int64
    var next: Optional[Int64]

    def __init__(out self):
        self.value = Int64(0)
        self.next = Optional[Int64]()

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_map_header_len(0 + 1 + (1 if self.next else 0))
        n += encoded_str_len(5)
        n += encoded_int_len(self.value)
        if self.next:
            n += encoded_str_len(4)
            n += encoded_int_len(self.next.value())
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.ensure(self.encoded_len(options) + 16)
        var p = w.pos
        var _mc = 0 + 1 + (1 if self.next else 0)
        if _mc <= 15:
            w.buf[p] = Byte(128 + _mc)
            p += 1
        else:
            w.pos = p
            w.write_map_header(_mc)
            p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(111555003905701)
        p += 6
        var _iv_value = self.value
        if _iv_value >= Int64(-32) and _iv_value <= Int64(127):
            w.buf[p] = Byte(Int(_iv_value) & 255)
            p += 1
        else:
            w.pos = p
            w.write_int(_iv_value)
            p = w.pos
        if self.next:
            w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(500236119716)
            p += 5
            var _iv_next = self.next.value()
            if _iv_next >= Int64(-32) and _iv_next <= Int64(127):
                w.buf[p] = Byte(Int(_iv_next) & 255)
                p += 1
            else:
                w.pos = p
                w.write_int(_iv_next)
                p = w.pos
        w.pos = p

    def _decode_expected[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError -> Bool:
        if not r.try_eat_fixstr("value".as_bytes()):
            return False
        self.value = r.read_i64()
        if not r.try_eat_fixstr("next".as_bytes()):
            return False
        if r.peek_is_nil():
            r.read_nil()
            self.next = None
        else:
            self.next = r.read_i64()
        return True

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var n = r.read_map_header()
        var saved = r.pos
        if n == 2 and self._decode_expected(r):
            return
        r.pos = saved
        var seen_value = False
        var i = 0
        while i < n:
            if not r.peek_is_str():
                r.skip_value()
                r.skip_value()
                i += 1
                continue
            var key = r.read_str()
            if key == "value":
                seen_value = True
                self.value = r.read_i64()
            elif key == "next":
                if r.peek_is_nil():
                    r.read_nil()
                    self.next = None
                else:
                    self.next = r.read_i64()
            else:
                r.skip_value()
            i += 1
        if not seen_value:
            raise DecodeError(DecodeError.KIND_SCHEMA, r.position())
