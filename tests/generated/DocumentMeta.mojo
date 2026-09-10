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
        w.ensure(self.encoded_len(options) + 16)
        var p = w.pos
        var _mc = 0 + 1 + 1
        if _mc <= 15:
            w.buf[p] = Byte(128 + _mc)
            p += 1
        else:
            w.pos = p
            w.write_map_header(_mc)
            p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(31084745935123110)
        p += 7
        var _sb_region = self.region.as_bytes()
        var _sn_region = len(_sb_region)
        if _sn_region <= 31:
            w.buf[p] = Byte(160 + _sn_region)
            p += 1
            if _sn_region > 0:
                w.pos = p
                w.write_bytes(_sb_region)
                p = w.pos
        else:
            w.pos = p
            w.write_str(self.region)
            p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(7957695011148363431)
        p += 8
        var _iv_version = self.version
        if _iv_version >= Int64(-32) and _iv_version <= Int64(127):
            w.buf[p] = Byte(Int(_iv_version) & 255)
            p += 1
        else:
            w.pos = p
            w.write_int(_iv_version)
            p = w.pos
        w.pos = p

    def _decode_expected[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError -> Bool:
        if not r.try_eat_fixstr("region".as_bytes()):
            return False
        self.region = r.read_str()
        if not r.try_eat_fixstr("version".as_bytes()):
            return False
        self.version = r.read_i64()
        return True

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var n = r.read_map_header()
        var saved = r.pos
        if n == 2 and self._decode_expected(r):
            return
        r.pos = saved
        var seen_region = False
        var seen_version = False
        var i = 0
        while i < n:
            if not r.peek_is_str():
                r.skip_value()
                r.skip_value()
                i += 1
                continue
            var key = r.read_str()
            if key == "region":
                seen_region = True
                self.region = r.read_str()
            elif key == "version":
                seen_version = True
                self.version = r.read_i64()
            else:
                r.skip_value()
            i += 1
        if not seen_region:
            raise DecodeError(DecodeError.KIND_SCHEMA, r.position())
        if not seen_version:
            raise DecodeError(DecodeError.KIND_SCHEMA, r.position())
