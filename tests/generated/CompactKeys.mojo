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

struct CompactKeys(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var a: Bool
    var b: Int64

    def __init__(out self):
        self.a = False
        self.b = Int64(0)

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_map_header_len(0 + 1 + 1)
        n += encoded_int_len(Int64(0))
        n += 1
        n += encoded_int_len(Int64(1))
        n += encoded_int_len(self.b)
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.ensure(self.encoded_len(options) + 16)
        var p = w.pos
        var _mc = 0 + 1 + 1
        if _mc <= 15:
            w.buf[p] = Byte(128 + _mc)
            p += 1
        else:
            w.pos = p
            w.write_map_header(_mc)
            p = w.pos
        var _iv_ka = Int64(0)
        if _iv_ka >= Int64(-32) and _iv_ka <= Int64(127):
            w.buf[p] = Byte(Int(_iv_ka) & 255)
            p += 1
        else:
            w.pos = p
            w.write_int(_iv_ka)
            p = w.pos
        if self.a:
            w.buf[p] = Byte(195)
        else:
            w.buf[p] = Byte(194)
        p += 1
        var _iv_kb = Int64(1)
        if _iv_kb >= Int64(-32) and _iv_kb <= Int64(127):
            w.buf[p] = Byte(Int(_iv_kb) & 255)
            p += 1
        else:
            w.pos = p
            w.write_int(_iv_kb)
            p = w.pos
        var _iv_b = self.b
        if _iv_b >= Int64(-32) and _iv_b <= Int64(127):
            w.buf[p] = Byte(Int(_iv_b) & 255)
            p += 1
        else:
            w.pos = p
            w.write_int(_iv_b)
            p = w.pos
        w.pos = p

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var n = r.read_map_header()
        var seen_a = False
        var seen_b = False
        var i = 0
        while i < n:
            var key = r.read_int_key()
            if not key:
                r.skip_value()
                i += 1
                continue
            var k = key.value()
            if k == Int64(0):
                seen_a = True
                self.a = r.read_bool()
            elif k == Int64(1):
                seen_b = True
                self.b = r.read_i64()
            else:
                r.skip_value()
            i += 1
        if not seen_a:
            raise DecodeError(DecodeError.KIND_SCHEMA, r.position())
        if not seen_b:
            raise DecodeError(DecodeError.KIND_SCHEMA, r.position())
