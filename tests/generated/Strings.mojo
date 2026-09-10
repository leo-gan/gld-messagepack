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

struct Strings(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var items: List[String]

    def __init__(out self):
        self.items = List[String]()

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_map_header_len(0 + 1)
        n += encoded_str_len(5)
        n += 8 + len(self.items) * 8
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.write_map_header(0 + 1)
        w.write_lit(UInt64(126913690757541), 6)
        w.write_array_header(len(self.items))
        var i = 0
        while i < len(self.items):
            w.write_str(self.items[i])
            i += 1

    def _decode_expected[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError -> Bool:
        if not r.try_eat_fixstr("items".as_bytes()):
            return False
        var _ln = r.read_array_header()
        self.items = List[String](capacity=_ln)
        var _j = 0
        while _j < _ln:
            self.items.append(r.read_str())
            _j += 1
        return True

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var n = r.read_map_header()
        var saved = r.pos
        if n == 1 and self._decode_expected(r):
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
            if key == "items":
                var _ln = r.read_array_header()
                self.items = List[String](capacity=_ln)
                var _j = 0
                while _j < _ln:
                    self.items.append(r.read_str())
                    _j += 1
            else:
                r.skip_value()
            i += 1
