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

struct Telemetry(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var values: List[Float64]

    def __init__(out self):
        self.values = List[Float64]()

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_map_header_len(0 + 1)
        n += encoded_str_len(6)
        n += 8 + len(self.values) * 8
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.ensure(512)
        var p = w.pos
        w.buf[p] = Byte(128 + 0 + 1)
        p += 1
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(32481177325631142)
        p += 7
        var _an_values = len(self.values)
        if _an_values <= 15:
            w.buf[p] = Byte(144 + _an_values)
            p += 1
        else:
            w.pos = p
            w.write_array_header(_an_values)
            p = w.pos
        var _ai_values = 0
        while _ai_values < _an_values:
            var _fb_avalues = UInt64(self.values[_ai_values].to_bits())
            w.buf[p] = Byte(203)
            w.buf.unsafe_ptr().unsafe_offset(p + 1).unsafe_bitcast[UInt64]()[] = (((_fb_avalues & UInt64(0x00000000000000FF)) << UInt64(56)) | ((_fb_avalues & UInt64(0x000000000000FF00)) << UInt64(40)) | ((_fb_avalues & UInt64(0x0000000000FF0000)) << UInt64(24)) | ((_fb_avalues & UInt64(0x00000000FF000000)) << UInt64(8)) | ((_fb_avalues & UInt64(0x000000FF00000000)) >> UInt64(8)) | ((_fb_avalues & UInt64(0x0000FF0000000000)) >> UInt64(24)) | ((_fb_avalues & UInt64(0x00FF000000000000)) >> UInt64(40)) | ((_fb_avalues & UInt64(0xFF00000000000000)) >> UInt64(56)))
            p += 9
            _ai_values += 1
        w.pos = p

    def _decode_expected[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError -> Bool:
        if not r.try_eat_fixstr("values".as_bytes()):
            return False
        var _ln = r.read_array_header()
        self.values = List[Float64](capacity=_ln)
        var _j = 0
        while _j < _ln:
            self.values.append(r.read_as_f64())
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
            if key == "values":
                var _ln = r.read_array_header()
                self.values = List[Float64](capacity=_ln)
                var _j = 0
                while _j < _ln:
                    self.values.append(r.read_as_f64())
                    _j += 1
            else:
                r.skip_value()
            i += 1
