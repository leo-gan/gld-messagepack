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
from EventAttr import EventAttr

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
        w.write_lit(UInt64(7566498), 3)
        w.write_int(self.ts)
        w.write_lit(UInt64(126935417250213), 6)
        w.write_array_header(len(self.attrs))
        var i = 0
        while i < len(self.attrs):
            self.attrs[i].encode_to(w, options)
            i += 1

    def _decode_expected[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError -> Bool:
        if not r.try_eat_fixstr("ts".as_bytes()):
            return False
        self.ts = r.read_i64()
        if not r.try_eat_fixstr("attrs".as_bytes()):
            return False
        var _ln = r.read_array_header()
        self.attrs = List[EventAttr](capacity=_ln)
        var _j = 0
        while _j < _ln:
            var _it = EventAttr()
            _it.decode_from(r)
            self.attrs.append(_it^)
            _j += 1
        return True

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var n = r.read_map_header()
        var saved = r.pos
        if n == 2 and self._decode_expected(r):
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
            if key == "ts":
                self.ts = r.read_i64()
            elif key == "attrs":
                var _ln = r.read_array_header()
                self.attrs = List[EventAttr](capacity=_ln)
                var _j = 0
                while _j < _ln:
                    var _it = EventAttr()
                    _it.decode_from(r)
                    self.attrs.append(_it^)
                    _j += 1
            else:
                r.skip_value()
            i += 1
