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

struct Compact(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var a: Bool
    var b: Int64

    def __init__(out self):
        self.a = False
        self.b = Int64(0)

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_array_header_len(2)
        n += 1
        n += encoded_int_len(self.b)
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.write_array_header(2)
        w.write_bool(self.a)
        w.write_int(self.b)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var n = r.read_array_header()
        if n != 2:
            raise DecodeError(DecodeError.KIND_TYPE, r.position())
        self.a = r.read_bool()
        self.b = r.read_i64()
