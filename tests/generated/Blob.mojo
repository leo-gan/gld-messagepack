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

struct Blob(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var data: List[Byte]

    def __init__(out self):
        self.data = List[Byte]()

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_map_header_len(0 + 1)
        n += encoded_str_len(4)
        n += encoded_bin_len(len(self.data))
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.ensure(self.encoded_len(options) + 16)
        var p = w.pos
        var _mc = 0 + 1
        if _mc <= 15:
            w.buf[p] = Byte(128 + _mc)
            p += 1
        else:
            w.pos = p
            w.write_map_header(_mc)
            p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(418564367524)
        p += 5
        w.pos = p
        w.write_bin(self.data)
        p = w.pos
        w.pos = p

    def _decode_expected[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError -> Bool:
        if not r.try_eat_fixstr("data".as_bytes()):
            return False
        self.data = r.read_bin()
        return True

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var n = r.read_map_header()
        var saved = r.pos
        if n == 1 and self._decode_expected(r):
            return
        r.pos = saved
        var seen_data = False
        var i = 0
        while i < n:
            if not r.peek_is_str():
                r.skip_value()
                r.skip_value()
                i += 1
                continue
            var key = r.read_str()
            if key == "data":
                seen_data = True
                self.data = r.read_bin()
            else:
                r.skip_value()
            i += 1
        if not seen_data:
            raise DecodeError(DecodeError.KIND_SCHEMA, r.position())
