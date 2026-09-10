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

struct Event(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var ts: Int64
    var attrs: List[EventAttr]

    def __init__(out self):
        self.ts = Int64(0)
        self.attrs = List[EventAttr]()

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_map_header_len(0 + 1 + 1)
        n += encoded_str_len(2)
        n += encoded_int_len(self.ts)
        n += encoded_str_len(5)
        n += 8 + len(self.attrs) * 8
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.write_map_header(0 + 1 + 1)
        w.write_str("ts")
        w.write_int(self.ts)
        w.write_str("attrs")
        w.write_array_header(len(self.attrs))
        var i = 0
        while i < len(self.attrs):
            self.attrs[i].encode_to(w, options)
            i += 1

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
            if key == "ts":
                self.ts = r.read_i64()
            elif key == "attrs":
                self.attrs = EventAttr()
            else:
                r.skip_value()
            i += 1
