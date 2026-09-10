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

struct LongList(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var value: Int64
    var next: Optional[Int64]

    def __init__(out self):
        self.value = Int64(0)
        self.next = Optional[Int64]()

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_map_header_len(0 + 1 + (1 if self.next else 0))
        n += encoded_str_len(5)
        n += encoded_int_len(self.value)
        if self.next:
            n += encoded_str_len(4)
            n += encoded_int_len(self.next.value())
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.write_map_header(0 + 1 + (1 if self.next else 0))
        w.write_str("value")
        w.write_int(self.value)
        if self.next:
            w.write_str("next")
            w.write_int(self.next.value())

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
            if key == "value":
                self.value = r.read_i64()
            elif key == "next":
                if r.peek_is_nil():
                    r.read_nil()
                    self.next = None
                else:
                    self.next = r.read_i64()
            else:
                r.skip_value()
            i += 1
