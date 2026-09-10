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
        w.ensure(512)
        var p = w.pos
        w.buf[p] = Byte(128 + 0 + 1 + 1)
        p += 1
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(2036689827)
        p += 4
        var _sb_key = self.key.as_bytes()
        var _sn_key = len(_sb_key)
        w.buf[p] = Byte(160 + _sn_key)
        p += 1
        if _sn_key > 0:
            w.pos = p
            w.write_bytes(_sb_key)
            p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(111555003905701)
        p += 6
        var _sb_value = self.value.as_bytes()
        var _sn_value = len(_sb_value)
        w.buf[p] = Byte(160 + _sn_value)
        p += 1
        if _sn_value > 0:
            w.pos = p
            w.write_bytes(_sb_value)
            p = w.pos
        w.pos = p

    def _decode_expected[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError -> Bool:
        if not r.try_eat_fixstr("key".as_bytes()):
            return False
        self.key = r.read_str()
        if not r.try_eat_fixstr("value".as_bytes()):
            return False
        self.value = r.read_str()
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
            if key == "key":
                self.key = r.read_str()
            elif key == "value":
                self.value = r.read_str()
            else:
                r.skip_value()
            i += 1
