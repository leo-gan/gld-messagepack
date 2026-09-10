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
        w.ensure(self.encoded_len(options) + 16)
        var p = w.pos
        var _mc = 0 + 1 + 1 + 1
        if _mc <= 15:
            w.buf[p] = Byte(128 + _mc)
            p += 1
        else:
            w.pos = p
            w.write_map_header(_mc)
            p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(1969976227)
        p += 4
        var _sb_sku = self.sku.as_bytes()
        var _sn_sku = len(_sb_sku)
        if _sn_sku <= 31:
            w.buf[p] = Byte(160 + _sn_sku)
            p += 1
            if _sn_sku > 0:
                w.pos = p
                w.write_bytes(_sb_sku)
                p = w.pos
        else:
            w.pos = p
            w.write_str(self.sku)
            p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(2037674403)
        p += 4
        var _iv_qty = self.qty
        if _iv_qty >= Int64(-32) and _iv_qty <= Int64(127):
            w.buf[p] = Byte(Int(_iv_qty) & 255)
            p += 1
        else:
            w.pos = p
            w.write_int(_iv_qty)
            p = w.pos
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(7881129350566932651)
        p += 8
        w.buf.unsafe_ptr().unsafe_offset(p).unsafe_bitcast[UInt64]()[] = UInt64(1919905385)
        p += 4
        var _iv_price_minor = self.price_minor
        if _iv_price_minor >= Int64(-32) and _iv_price_minor <= Int64(127):
            w.buf[p] = Byte(Int(_iv_price_minor) & 255)
            p += 1
        else:
            w.pos = p
            w.write_int(_iv_price_minor)
            p = w.pos
        w.pos = p

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
        var seen_sku = False
        var seen_qty = False
        var seen_price_minor = False
        var i = 0
        while i < n:
            if not r.peek_is_str():
                r.skip_value()
                r.skip_value()
                i += 1
                continue
            var key = r.read_str()
            if key == "sku":
                seen_sku = True
                self.sku = r.read_str()
            elif key == "qty":
                seen_qty = True
                self.qty = r.read_i64()
            elif key == "price_minor":
                seen_price_minor = True
                self.price_minor = r.read_i64()
            else:
                r.skip_value()
            i += 1
        if not seen_sku:
            raise DecodeError(DecodeError.KIND_SCHEMA, r.position())
        if not seen_qty:
            raise DecodeError(DecodeError.KIND_SCHEMA, r.position())
        if not seen_price_minor:
            raise DecodeError(DecodeError.KIND_SCHEMA, r.position())
