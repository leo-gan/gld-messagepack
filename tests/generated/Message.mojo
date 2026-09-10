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
        w.write_map_header(0 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1)
        w.write_lit(UInt64(30521821667223206), 7)
        w.write_bool(self.f_bool)
        w.write_lit(UInt64(3617362943271724711), 8)
        w.write_int(self.f_int32)
        w.write_lit(UInt64(3762322556277712551), 8)
        w.write_int(self.f_int64)
        w.write_fixstr("f_float64".as_bytes())
        w.write_f64(self.f_float64)
        w.write_fixstr("f_string".as_bytes())
        w.write_str(self.f_string)
        w.write_fixstr("f_bool_2".as_bytes())
        w.write_bool(self.f_bool_2)
        w.write_fixstr("f_int32_2".as_bytes())
        w.write_int(self.f_int32_2)
        w.write_fixstr("f_string_2".as_bytes())
        w.write_str(self.f_string_2)

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
