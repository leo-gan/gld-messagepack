from std.collections import List

from msgpack import DecodeError, EncodeOptions, MsgpackDatum, WireReader, WireWriter
from wire.writer import encoded_f64_len, encoded_int_len, encoded_map_header_len, encoded_str_len


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
        var n = encoded_map_header_len(8)
        n += encoded_str_len(6) + 1
        n += encoded_int_len(self.f_int32) + encoded_str_len(7)
        n += encoded_int_len(self.f_int64) + encoded_str_len(7)
        n += encoded_f64_len() + encoded_str_len(9)
        n += encoded_str_len(self.f_string.byte_length()) + encoded_str_len(8)
        n += 1 + encoded_str_len(8)
        n += encoded_int_len(self.f_int32_2) + encoded_str_len(9)
        n += encoded_str_len(self.f_string_2.byte_length()) + encoded_str_len(10)
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.write_map_header(8)
        w.write_str("f_bool")
        w.write_bool(self.f_bool)
        w.write_str("f_int32")
        w.write_int(self.f_int32)
        w.write_str("f_int64")
        w.write_int(self.f_int64)
        w.write_str("f_float64")
        w.write_f64(self.f_float64)
        w.write_str("f_string")
        w.write_str(self.f_string)
        w.write_str("f_bool_2")
        w.write_bool(self.f_bool_2)
        w.write_str("f_int32_2")
        w.write_int(self.f_int32_2)
        w.write_str("f_string_2")
        w.write_str(self.f_string_2)

    def decode_from[
        origin: ImmOrigin
    ](mut self, mut r: WireReader[origin]) raises DecodeError:
        var n = r.read_map_header()
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
