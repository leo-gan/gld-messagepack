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

struct Stamp(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var when: MsgpackTimestamp

    def __init__(out self):
        self.when = MsgpackTimestamp()

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_map_header_len(0 + 1)
        n += encoded_str_len(4)
        n += self.when.encoded_len()
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.write_map_header(0 + 1)
        w.write_str("when")
        self.when.encode_to(w)

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
            if key == "when":
                var _ts = r.read_timestamp()
                    self.when = MsgpackTimestamp(_ts[0], _ts[1])
            else:
                r.skip_value()
            i += 1
