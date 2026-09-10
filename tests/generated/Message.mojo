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

struct Message(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var f_bool: Bool
    var f_int32: Int64
    var f_int64: Int64
    var f_float64: Float64
    var f_string: String
    var f_bool_2: Bool
    var f_int32_2: Int64
    var f_string_2: String

    def __init__(out self):
        self.f_bool = False
        self.f_int32 = Int64(0)
        self.f_int64 = Int64(0)
        self.f_float64 = 0.0
        self.f_string = String()
        self.f_bool_2 = False
        self.f_int32_2 = Int64(0)
        self.f_string_2 = String()

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_map_header_len(0 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1)
        n += encoded_str_len(6)
        n += 1
        n += encoded_str_len(7)
        n += encoded_int_len(self.f_int32)
        n += encoded_str_len(7)
        n += encoded_int_len(self.f_int64)
        n += encoded_str_len(9)
        n += encoded_f64_len()
        n += encoded_str_len(8)
        n += encoded_str_len(self.f_string.byte_length())
        n += encoded_str_len(8)
        n += 1
        n += encoded_str_len(9)
        n += encoded_int_len(self.f_int32_2)
        n += encoded_str_len(10)
        n += encoded_str_len(self.f_string_2.byte_length())
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.ensure(512)
        var p = w.pos
        w.buf[p] = Byte(128 + 0 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1)
        p += 1
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(30521821667223206 | ((UInt64(194) + UInt64(Int(self.f_bool))) << UInt64(56)))
        p += 8
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(3617362943271724711)
        p += 8
        var _iv_f_int32 = self.f_int32
        if _iv_f_int32 >= Int64(-32) and _iv_f_int32 <= Int64(127):
            w.buf[p] = Byte(Int(_iv_f_int32) & 255)
            p += 1
        else:
            w.pos = p
            w.write_int(_iv_f_int32)
            p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(3762322556277712551)
        p += 8
        var _iv_f_int64 = self.f_int64
        if _iv_f_int64 >= Int64(-32) and _iv_f_int64 <= Int64(127):
            w.buf[p] = Byte(Int(_iv_f_int64) & 255)
            p += 1
        else:
            w.pos = p
            w.write_int(_iv_f_int64)
            p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(8386106492505253545)
        p += 8
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(13366)
        p += 2
        var _fb_f_float64 = UInt64(self.f_float64.to_bits())
        w.buf[p] = Byte(203)
        w.buf.unsafe_ptr().unsafe_offset(p + 1).unsafe_bitcast[UInt64]()[] = (((_fb_f_float64 & UInt64(0x00000000000000FF)) << UInt64(56)) | ((_fb_f_float64 & UInt64(0x000000000000FF00)) << UInt64(40)) | ((_fb_f_float64 & UInt64(0x0000000000FF0000)) << UInt64(24)) | ((_fb_f_float64 & UInt64(0x00000000FF000000)) << UInt64(8)) | ((_fb_f_float64 & UInt64(0x000000FF00000000)) >> UInt64(8)) | ((_fb_f_float64 & UInt64(0x0000FF0000000000)) >> UInt64(24)) | ((_fb_f_float64 & UInt64(0x00FF000000000000)) >> UInt64(40)) | ((_fb_f_float64 & UInt64(0xFF00000000000000)) >> UInt64(56)))
        p += 9
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(7956016061204096680)
        p += 8
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(103)
        p += 1
        var _sb_f_string = self.f_string.as_bytes()
        var _sn_f_string = len(_sb_f_string)
        w.buf[p] = Byte(160 + _sn_f_string)
        p += 1
        if _sn_f_string > 0:
            w.pos = p
            w.write_bytes(_sb_f_string)
            p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(6875993255270377128)
        p += 8
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(50)
        p += 1
        if self.f_bool_2:
            w.buf[p] = Byte(195)
        else:
            w.buf[p] = Byte(194)
        p += 1
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(3617362943271724713)
        p += 8
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(12895)
        p += 2
        var _iv_f_int32_2 = self.f_int32_2
        if _iv_f_int32_2 >= Int64(-32) and _iv_f_int32_2 <= Int64(127):
            w.buf[p] = Byte(Int(_iv_f_int32_2) & 255)
            p += 1
        else:
            w.pos = p
            w.write_int(_iv_f_int32_2)
            p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(7956016061204096682)
        p += 8
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(3301223)
        p += 3
        var _sb_f_string_2 = self.f_string_2.as_bytes()
        var _sn_f_string_2 = len(_sb_f_string_2)
        w.buf[p] = Byte(160 + _sn_f_string_2)
        p += 1
        if _sn_f_string_2 > 0:
            w.pos = p
            w.write_bytes(_sb_f_string_2)
            p = w.pos
        w.pos = p

    def _decode_expected[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError -> Bool:
        if not r.try_eat_fixstr("f_bool".as_bytes()):
            return False
        self.f_bool = r.read_bool()
        if not r.try_eat_fixstr("f_int32".as_bytes()):
            return False
        self.f_int32 = r.read_i64()
        if not r.try_eat_fixstr("f_int64".as_bytes()):
            return False
        self.f_int64 = r.read_i64()
        if not r.try_eat_fixstr("f_float64".as_bytes()):
            return False
        self.f_float64 = r.read_as_f64()
        if not r.try_eat_fixstr("f_string".as_bytes()):
            return False
        self.f_string = r.read_str()
        if not r.try_eat_fixstr("f_bool_2".as_bytes()):
            return False
        self.f_bool_2 = r.read_bool()
        if not r.try_eat_fixstr("f_int32_2".as_bytes()):
            return False
        self.f_int32_2 = r.read_i64()
        if not r.try_eat_fixstr("f_string_2".as_bytes()):
            return False
        self.f_string_2 = r.read_str()
        return True

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var n = r.read_map_header()
        var saved = r.pos
        if n == 8 and self._decode_expected(r):
            return
        r.pos = saved
        var i = 0
        while i < n:
            if not r.peek_is_str():
                r.skip_value()
                r.skip_value()
                i += 1
                continue
            var key = r.read_str()
            if key == "f_bool":
                self.f_bool = r.read_bool()
            elif key == "f_int32":
                self.f_int32 = r.read_i64()
            elif key == "f_int64":
                self.f_int64 = r.read_i64()
            elif key == "f_float64":
                self.f_float64 = r.read_as_f64()
            elif key == "f_string":
                self.f_string = r.read_str()
            elif key == "f_bool_2":
                self.f_bool_2 = r.read_bool()
            elif key == "f_int32_2":
                self.f_int32_2 = r.read_i64()
            elif key == "f_string_2":
                self.f_string_2 = r.read_str()
            else:
                r.skip_value()
            i += 1
