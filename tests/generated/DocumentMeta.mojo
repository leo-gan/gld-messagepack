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

struct DocumentMeta(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var region: String
    var version: Int64

    def __init__(out self):
        self.region = String()
        self.version = Int64(0)

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_map_header_len(0 + 1 + 1)
        n += encoded_str_len(6)
        n += encoded_str_len(self.region.byte_length())
        n += encoded_str_len(7)
        n += encoded_int_len(self.version)
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.write_map_header(0 + 1 + 1)
        w.write_str("region")
        w.write_str(self.region)
        w.write_str("version")
        w.write_int(self.version)

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
            if key == "region":
                self.region = r.read_str()
            elif key == "version":
                self.version = r.read_i64()
            else:
                r.skip_value()
            i += 1
