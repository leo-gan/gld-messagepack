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

struct EventAttr(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var key: String
    var value: String

    def __init__(out self):
        self.key = String()
        self.value = String()

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_map_header_len(0 + 1 + 1)
        n += encoded_str_len(3)
        n += encoded_str_len(self.key.byte_length())
        n += encoded_str_len(5)
        n += encoded_str_len(self.value.byte_length())
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.write_map_header(0 + 1 + 1)
        w.write_str("key")
        w.write_str(self.key)
        w.write_str("value")
        w.write_str(self.value)

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
            if key == "key":
                self.key = r.read_str()
            elif key == "value":
                self.value = r.read_str()
            else:
                r.skip_value()
            i += 1
