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

struct DocumentItem(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):
    var sku: String
    var qty: Int64
    var price_minor: Int64

    def __init__(out self):
        self.sku = String()
        self.qty = Int64(0)
        self.price_minor = Int64(0)

    def encoded_len(self, options: EncodeOptions) -> Int:
        _ = options
        var n = encoded_map_header_len(0 + 1 + 1 + 1)
        n += encoded_str_len(3)
        n += encoded_str_len(self.sku.byte_length())
        n += encoded_str_len(3)
        n += encoded_int_len(self.qty)
        n += encoded_str_len(11)
        n += encoded_int_len(self.price_minor)
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        _ = options
        w.write_map_header(0 + 1 + 1 + 1)
        w.write_lit(UInt64(1969976227), 4)
        w.write_str(self.sku)
        w.write_lit(UInt64(2037674403), 4)
        w.write_int(self.qty)
        w.write_fixstr("price_minor".as_bytes())
        w.write_int(self.price_minor)

    def _decode_expected[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError -> Bool:
        if not r.try_eat_fixstr("sku".as_bytes()):
            return False
        self.sku = r.read_str()
        if not r.try_eat_fixstr("qty".as_bytes()):
            return False
        self.qty = r.read_i64()
        if not r.try_eat_fixstr("price_minor".as_bytes()):
            return False
        self.price_minor = r.read_i64()
        return True

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var n = r.read_map_header()
        var saved = r.pos
        if n == 3 and self._decode_expected(r):
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
            if key == "sku":
                self.sku = r.read_str()
            elif key == "qty":
                self.qty = r.read_i64()
            elif key == "price_minor":
                self.price_minor = r.read_i64()
            else:
                r.skip_value()
            i += 1
