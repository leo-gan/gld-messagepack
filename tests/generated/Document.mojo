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
from DocumentMeta import DocumentMeta
from DocumentItem import DocumentItem

struct Document(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var id: String
    var status: Int64
    var meta: DocumentMeta
    var items: List[DocumentItem]

    def __init__(out self):
        self.id = String()
        self.status = Int64(0)
        self.meta = DocumentMeta()
        self.items = List[DocumentItem]()

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_map_header_len(0 + 1 + 1 + 1 + 1)
        n += encoded_str_len(2)
        n += encoded_str_len(self.id.byte_length())
        n += encoded_str_len(6)
        n += encoded_int_len(self.status)
        n += encoded_str_len(4)
        n += self.meta.encoded_len(options)
        n += encoded_str_len(5)
        n += 8 + len(self.items) * 8
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.ensure(512)
        var p = w.pos
        w.buf[p] = Byte(128 + 0 + 1 + 1 + 1 + 1)
        p += 1
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(6580642)
        p += 3
        var _sb_id = self.id.as_bytes()
        var _sn_id = len(_sb_id)
        w.buf[p] = Byte(160 + _sn_id)
        p += 1
        if _sn_id > 0:
            w.pos = p
            w.write_bytes(_sb_id)
            p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(32498765033403302)
        p += 7
        var _iv_status = self.status
        if _iv_status >= Int64(-32) and _iv_status <= Int64(127):
            w.buf[p] = Byte(Int(_iv_status) & 255)
            p += 1
        else:
            w.pos = p
            w.write_int(_iv_status)
            p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(418564631972)
        p += 5
        w.pos = p
        self.meta.encode_to(w, options)
        p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(126913690757541)
        p += 6
        w.pos = p
        w.write_array_header(len(self.items))
        var i = 0
        while i < len(self.items):
            self.items[i].encode_to(w, options)
            i += 1
        p = w.pos
        w.pos = p

    def _decode_expected[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError -> Bool:
        if not r.try_eat_fixstr("id".as_bytes()):
            return False
        self.id = r.read_str()
        if not r.try_eat_fixstr("status".as_bytes()):
            return False
        self.status = r.read_i64()
        if not r.try_eat_fixstr("meta".as_bytes()):
            return False
        self.meta = DocumentMeta()
        self.meta.decode_from(r)
        if not r.try_eat_fixstr("items".as_bytes()):
            return False
        var _ln = r.read_array_header()
        self.items = List[DocumentItem](capacity=_ln)
        var _j = 0
        while _j < _ln:
            var _it = DocumentItem()
            _it.decode_from(r)
            self.items.append(_it^)
            _j += 1
        return True

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var n = r.read_map_header()
        var saved = r.pos
        if n == 4 and self._decode_expected(r):
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
            if key == "id":
                self.id = r.read_str()
            elif key == "status":
                self.status = r.read_i64()
            elif key == "meta":
                self.meta = DocumentMeta()
                self.meta.decode_from(r)
            elif key == "items":
                var _ln = r.read_array_header()
                self.items = List[DocumentItem](capacity=_ln)
                var _j = 0
                while _j < _ln:
                    var _it = DocumentItem()
                    _it.decode_from(r)
                    self.items.append(_it^)
                    _j += 1
            else:
                r.skip_value()
            i += 1
