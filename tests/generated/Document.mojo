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
        w.write_map_header(0 + 1 + 1 + 1 + 1)
        w.write_str("id")
        w.write_str(self.id)
        w.write_str("status")
        w.write_int(self.status)
        w.write_str("meta")
        self.meta.encode_to(w, options)
        w.write_str("items")
        w.write_array_header(len(self.items))
        var i = 0
        while i < len(self.items):
            self.items[i].encode_to(w, options)
            i += 1

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
            if key == "id":
                self.id = r.read_str()
            elif key == "status":
                self.status = r.read_i64()
            elif key == "meta":
                self.meta = DocumentMeta()
                    self.meta.decode_from(r)
            elif key == "items":
                self.items = DocumentItem()
            else:
                r.skip_value()
            i += 1
