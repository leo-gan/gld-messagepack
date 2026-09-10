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

struct Keywords(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var struct_: Int64
    var fn_: Int64
    var var_: String
    var match_: Bool

    def __init__(out self):
        self.struct_ = Int64(0)
        self.fn_ = Int64(0)
        self.var_ = String()
        self.match_ = False

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_map_header_len(0 + 1 + 1 + 1 + 1)
        n += encoded_str_len(6)
        n += encoded_int_len(self.struct_)
        n += encoded_str_len(2)
        n += encoded_int_len(self.fn_)
        n += encoded_str_len(3)
        n += encoded_str_len(self.var_.byte_length())
        n += encoded_str_len(5)
        n += 1
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.write_map_header(0 + 1 + 1 + 1 + 1)
        w.write_str("struct")
        w.write_int(self.struct_)
        w.write_str("fn")
        w.write_int(self.fn_)
        w.write_str("var")
        w.write_str(self.var_)
        w.write_str("match")
        w.write_bool(self.match_)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var n = r.read_map_header()
        var i = 0
        while i < n:
            if not r.peek_is_str():
                r.skip_value()
                r.skip_value()
                i += 1
                continue
            var key = r.read_str()
            if key == "struct":
                self.struct_ = r.read_i64()
            elif key == "fn":
                self.fn_ = r.read_i64()
            elif key == "var":
                self.var_ = r.read_str()
            elif key == "match":
                self.match_ = r.read_bool()
            else:
                r.skip_value()
            i += 1
