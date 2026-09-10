from std.collections import List

from codegen.names import mojo_ident
from runtime.error import DecodeError
from schema.model import (
    ENC_ARRAY,
    ENC_INTKEYS,
    ENC_MAP,
    ST_ARRAY,
    ST_BOOL,
    ST_BYTES,
    ST_CONST,
    ST_ENUM,
    ST_EXT,
    ST_INT,
    ST_NUMBER,
    ST_OBJECT,
    ST_OPTIONAL,
    ST_REF,
    ST_STRING,
    ST_TIMESTAMP,
    ST_UNION,
    SchemaDoc,
    SchemaType,
)
from schema.scc import scc_ids


def emit_all(doc: SchemaDoc) raises DecodeError -> List[String]:
    var files = List[String]()
    var seen = List[String]()
    _emit_named(doc, doc.root, files, seen)
    var i = 0
    while i < len(doc.def_types):
        _emit_named(doc, doc.def_types[i], files, seen)
        i += 1
    return files^


def _emit_named(
    doc: SchemaDoc, tid: Int, mut files: List[String], mut seen: List[String]
) raises DecodeError:
    var ty = _unwrap(doc, tid).copy()
    if ty.kind != ST_OBJECT and ty.kind != ST_UNION:
        return
    var name = ty.name
    if name.byte_length() == 0:
        name = String("Root")
    name = mojo_ident(name)
    var i = 0
    while i < len(seen):
        if seen[i] == name:
            return
        i += 1
    seen.append(name)
    if ty.kind == ST_OBJECT:
        var p = 0
        while p < len(ty.props):
            _emit_named(doc, ty.props[p].type_id, files, seen)
            p += 1
    if ty.kind == ST_UNION:
        var b = 0
        while b < len(ty.branch_ids):
            _emit_named(doc, ty.branch_ids[b], files, seen)
            b += 1
    files.append(name)
    files.append(_emit_struct(doc, tid, name))


def _unwrap(doc: SchemaDoc, tid: Int) -> SchemaType:
    var t = doc.types[tid].copy()
    while t.kind == ST_REF or t.kind == ST_OPTIONAL or t.kind == ST_ENUM or t.kind == ST_CONST:
        if t.inner < 0:
            break
        t = doc.types[t.inner].copy()
    return t^


def _type_name(doc: SchemaDoc, tid: Int, scc: List[Int], self_id: Int) -> String:
    var t = doc.types[tid].copy()
    if t.kind == ST_OPTIONAL:
        return "Optional[" + _type_name(doc, t.inner, scc, self_id) + "]"
    if t.kind == ST_ARRAY:
        return "List[" + _type_name(doc, t.inner, scc, self_id) + "]"
    if t.kind == ST_REF:
        return _type_name(doc, t.inner, scc, self_id)
    if t.kind == ST_ENUM or t.kind == ST_CONST:
        return _type_name(doc, t.inner, scc, self_id)
    if t.kind == ST_BOOL:
        return String("Bool")
    if t.kind == ST_INT:
        return String("Int64")
    if t.kind == ST_NUMBER:
        return String("Float64")
    if t.kind == ST_STRING:
        return String("String")
    if t.kind == ST_BYTES:
        return String("List[Byte]")
    if t.kind == ST_EXT:
        return String("MsgpackExt")
    if t.kind == ST_TIMESTAMP:
        return String("MsgpackTimestamp")
    if t.kind == ST_OBJECT or t.kind == ST_UNION:
        var n = mojo_ident(t.name)
        if self_id >= 0 and self_id < len(scc) and tid < len(scc):
            if scc[tid] == scc[self_id]:
                return "Box[" + n + "]"
        return n
    return String("Int64")


def _is_optional(doc: SchemaDoc, tid: Int) -> Bool:
    return doc.types[tid].kind == ST_OPTIONAL


def _key_word(name: String) -> UInt64:
    var b = name.as_bytes()
    var n = len(b)
    var w = UInt64(0xA0 | n)
    var i = 0
    while i < n:
        w = w | (UInt64(Int(b[i])) << UInt64(8 * (i + 1)))
        i += 1
    return w


def _named_refs(
    doc: SchemaDoc, ty: SchemaType, self_name: String, scc: List[Int], self_id: Int
) -> List[String]:
    var out = List[String]()
    var i = 0
    while i < len(ty.props):
        _collect_named(doc, ty.props[i].type_id, self_name, scc, self_id, out)
        i += 1
    i = 0
    while i < len(ty.branch_ids):
        _collect_named(doc, ty.branch_ids[i], self_name, scc, self_id, out)
        i += 1
    return out^


def _collect_named(
    doc: SchemaDoc,
    tid: Int,
    self_name: String,
    scc: List[Int],
    self_id: Int,
    mut out: List[String],
):
    var t = doc.types[tid].copy()
    if t.kind == ST_OPTIONAL or t.kind == ST_ARRAY or t.kind == ST_REF or t.kind == ST_ENUM or t.kind == ST_CONST:
        if t.inner >= 0:
            _collect_named(doc, t.inner, self_name, scc, self_id, out)
        return
    if t.kind != ST_OBJECT and t.kind != ST_UNION:
        return
    var n = mojo_ident(t.name)
    if n == self_name:
        return
    var j = 0
    while j < len(out):
        if out[j] == n:
            return
        j += 1
    out.append(n)



def _emit_struct(doc: SchemaDoc, tid: Int, name: String) raises DecodeError -> String:
    var ty = _unwrap(doc, tid).copy()
    var scc = scc_ids(doc)
    var out = String()
    out += "from std.collections import List, Optional, Span\n\n"
    out += "from msgpack import (\n"
    out += "    Box,\n"
    out += "    DecodeError,\n"
    out += "    EncodeOptions,\n"
    out += "    MsgpackDatum,\n"
    out += "    MsgpackExt,\n"
    out += "    MsgpackTimestamp,\n"
    out += "    WireReader,\n"
    out += "    WireWriter,\n"
    out += "    encoded_array_header_len,\n"
    out += "    encoded_bin_len,\n"
    out += "    encoded_ext_len,\n"
    out += "    encoded_f64_len,\n"
    out += "    encoded_int_len,\n"
    out += "    encoded_map_header_len,\n"
    out += "    encoded_str_len,\n"
    out += ")\n"
    var refs = _named_refs(doc, ty, name, scc, tid)
    var ri = 0
    while ri < len(refs):
        out += "from " + refs[ri] + " import " + refs[ri] + "\n"
        ri += 1
    out += "\n"
    if ty.kind == ST_UNION:
        return out + _emit_union(doc, ty, name, scc, tid)
    out += (
        "struct "
        + name
        + "(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):\n"
    )
    var i = 0
    while i < len(ty.props):
        var p = ty.props[i].copy()
        var fname = mojo_ident(p.name)
        var fty = _type_name(doc, p.type_id, scc, tid)
        out += "    var " + fname + ": " + fty + "\n"
        i += 1
    out += "\n    def __init__(out self):\n"
    if len(ty.props) == 0:
        out += "        pass\n"
    i = 0
    while i < len(ty.props):
        var p = ty.props[i].copy()
        var fname = mojo_ident(p.name)
        out += "        self." + fname + " = " + _zero(_type_name(doc, p.type_id, scc, tid)) + "\n"
        i += 1
    out += _emit_len(doc, ty, scc, tid)
    out += _emit_encode(doc, ty, scc, tid)
    out += _emit_decode(doc, ty, scc, tid)
    return out


def _zero(ty: String) -> String:
    if ty == "Bool":
        return String("False")
    if ty == "Int64":
        return String("Int64(0)")
    if ty == "Float64":
        return String("0.0")
    if ty == "MsgpackTimestamp":
        return String("MsgpackTimestamp()")
    if ty == "MsgpackExt":
        return String("MsgpackExt()")
    if _starts(ty, "Optional["):
        return ty + "()"
    if _starts(ty, "List["):
        return ty + "()"
    if _starts(ty, "Box["):
        return ty + "(" + _inner(ty) + "())"
    return ty + "()"


def _inner(ty: String) -> String:
    return _cut(ty, 4, ty.byte_length() - 1)


def _starts(s: String, prefix: String) -> Bool:
    if s.byte_length() < prefix.byte_length():
        return False
    var a = s.as_bytes()
    var b = prefix.as_bytes()
    var i = 0
    while i < len(b):
        if Int(a[i]) != Int(b[i]):
            return False
        i += 1
    return True


def _cut(s: String, start: Int, end: Int) -> String:
    var b = s.as_bytes()
    try:
        return String(from_utf8=b[start:end])
    except _:
        return String()


def _present_count_expr(ty: SchemaType) -> String:
    if ty.encoding == ENC_ARRAY:
        return String(len(ty.props))
    var out = String("0")
    var i = 0
    while i < len(ty.props):
        var p = ty.props[i].copy()
        var fname = mojo_ident(p.name)
        if p.required:
            out += " + 1"
        else:
            out += " + (1 if self." + fname + " else 0)"
        i += 1
    return out


def _emit_len(doc: SchemaDoc, ty: SchemaType, scc: List[Int], self_id: Int) -> String:
    var out = String()
    out += "\n    def encoded_len(self, options: EncodeOptions) -> Int:\n"
    out += "        _ = options\n"
    if ty.encoding == ENC_ARRAY:
        out += "        var n = encoded_array_header_len(" + String(len(ty.props)) + ")\n"
    else:
        out += "        var n = encoded_map_header_len(" + _present_count_expr(ty) + ")\n"
    var i = 0
    while i < len(ty.props):
        var p = ty.props[i].copy()
        var fname = mojo_ident(p.name)
        var opt = _is_optional(doc, p.type_id)
        var indent = "        "
        if opt and ty.encoding != ENC_ARRAY:
            out += "        if self." + fname + ":\n"
            indent = "            "
        if ty.encoding == ENC_MAP:
            out += indent + "n += encoded_str_len(" + String(p.name.byte_length()) + ")\n"
        elif ty.encoding == ENC_INTKEYS:
            out += indent + "n += encoded_int_len(Int64(" + String(p.int_key) + "))\n"
        out += indent + _len_stmt(doc, p.type_id, "self." + fname, scc, self_id, opt) + "\n"
        i += 1
    out += "        return n\n"
    return out


def _len_stmt(
    doc: SchemaDoc, tid: Int, acc: String, scc: List[Int], self_id: Int, through_opt: Bool
) -> String:
    var t = doc.types[tid].copy()
    if t.kind == ST_OPTIONAL:
        return _len_stmt(doc, t.inner, acc + ".value()", scc, self_id, True)
    if t.kind == ST_REF or t.kind == ST_ENUM or t.kind == ST_CONST:
        return _len_stmt(doc, t.inner, acc, scc, self_id, through_opt)
    if t.kind == ST_BOOL:
        return "n += 1"
    if t.kind == ST_INT:
        return "n += encoded_int_len(" + acc + ")"
    if t.kind == ST_NUMBER:
        return "n += encoded_f64_len()"
    if t.kind == ST_STRING:
        return "n += encoded_str_len(" + acc + ".byte_length())"
    if t.kind == ST_BYTES:
        return "n += encoded_bin_len(len(" + acc + "))"
    if t.kind == ST_TIMESTAMP:
        return "n += " + acc + ".encoded_len()"
    if t.kind == ST_EXT:
        return "n += encoded_ext_len(len(" + acc + ".data))"
    if t.kind == ST_ARRAY:
        return "n += 8 + len(" + acc + ") * 8"
    var call = acc
    if _starts(_type_name(doc, tid, scc, self_id), "Box["):
        call = acc + "[]"
    return "n += " + call + ".encoded_len(options)"


def _emit_encode(doc: SchemaDoc, ty: SchemaType, scc: List[Int], self_id: Int) -> String:
    var out = String()
    out += "\n    def encode_to(self, mut w: WireWriter, options: EncodeOptions):\n"
    out += "        _ = options\n"
    if ty.encoding == ENC_ARRAY:
        out += "        w.write_array_header(" + String(len(ty.props)) + ")\n"
    else:
        out += "        w.write_map_header(" + _present_count_expr(ty) + ")\n"
    var i = 0
    while i < len(ty.props):
        var p = ty.props[i].copy()
        var fname = mojo_ident(p.name)
        var opt = _is_optional(doc, p.type_id)
        var indent = "        "
        if opt and ty.encoding != ENC_ARRAY:
            out += "        if self." + fname + ":\n"
            indent = "            "
        if ty.encoding == ENC_MAP:
            if p.name.byte_length() <= 7:
                out += (
                    indent
                    + "w.write_lit(UInt64("
                    + String(_key_word(p.name))
                    + "), "
                    + String(p.name.byte_length() + 1)
                    + ")\n"
                )
            elif p.name.byte_length() <= 31:
                out += indent + "w.write_fixstr(\"" + p.name + "\".as_bytes())\n"
            else:
                out += indent + "w.write_str(\"" + p.name + "\")\n"
        elif ty.encoding == ENC_INTKEYS:
            out += indent + "w.write_int(Int64(" + String(p.int_key) + "))\n"
        if opt and ty.encoding == ENC_ARRAY:
            out += "        if self." + fname + ":\n"
            out += "            " + _enc_stmt(doc, p.type_id, "self." + fname, scc, self_id) + "\n"
            out += "        else:\n"
            out += "            w.write_nil()\n"
        else:
            out += indent + _enc_stmt(doc, p.type_id, "self." + fname, scc, self_id) + "\n"
        i += 1
    return out


def _enc_stmt(doc: SchemaDoc, tid: Int, acc: String, scc: List[Int], self_id: Int) -> String:
    var t = doc.types[tid].copy()
    if t.kind == ST_OPTIONAL:
        return _enc_stmt(doc, t.inner, acc + ".value()", scc, self_id)
    if t.kind == ST_REF or t.kind == ST_ENUM or t.kind == ST_CONST:
        return _enc_stmt(doc, t.inner, acc, scc, self_id)
    if t.kind == ST_BOOL:
        return "w.write_bool(" + acc + ")"
    if t.kind == ST_INT:
        return "w.write_int(" + acc + ")"
    if t.kind == ST_NUMBER:
        return "w.write_f64(" + acc + ")"
    if t.kind == ST_STRING:
        return "w.write_str(" + acc + ")"
    if t.kind == ST_BYTES:
        return "w.write_bin(" + acc + ")"
    if t.kind == ST_TIMESTAMP:
        return acc + ".encode_to(w)"
    if t.kind == ST_EXT:
        return "w.write_ext(" + acc + ".type, " + acc + ".data)"
    if t.kind == ST_ARRAY:
        return _enc_list(doc, t.inner, acc, scc, self_id)
    var call = acc
    if _starts(_type_name(doc, tid, scc, self_id), "Box["):
        call = acc + "[]"
    return call + ".encode_to(w, options)"


def _enc_list(doc: SchemaDoc, tid: Int, acc: String, scc: List[Int], self_id: Int) -> String:
    var item = _enc_stmt(doc, tid, acc + "[i]", scc, self_id)
    return (
        "w.write_array_header(len("
        + acc
        + "))\n        var i = 0\n        while i < len("
        + acc
        + "):\n            "
        + item
        + "\n            i += 1"
    )


def _emit_decode(doc: SchemaDoc, ty: SchemaType, scc: List[Int], self_id: Int) -> String:
    var out = String()
    out += "\n    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:\n"
    if ty.encoding == ENC_ARRAY:
        out += "        var n = r.read_array_header()\n"
        out += "        if n != " + String(len(ty.props)) + ":\n"
        out += "            raise DecodeError(DecodeError.KIND_TYPE, r.position())\n"
        var i = 0
        while i < len(ty.props):
            var p = ty.props[i].copy()
            var fname = mojo_ident(p.name)
            var opt = _is_optional(doc, p.type_id)
            if opt:
                out += "        if r.peek_is_nil():\n"
                out += "            r.read_nil()\n"
                out += "            self." + fname + " = None\n"
                out += "        else:\n"
                out += "            " + _dec_stmt(doc, p.type_id, "self." + fname, scc, self_id, "            ") + "\n"
            else:
                out += "        " + _dec_stmt(doc, p.type_id, "self." + fname, scc, self_id, "        ") + "\n"
            i += 1
        return out
    out += "        var n = r.read_map_header()\n"
    if ty.encoding == ENC_MAP:
        out += "        var saved = r.pos\n"
        out += "        if n == " + String(len(ty.props)) + " and self._decode_expected(r):\n"
        out += "            return\n"
        out += "        r.pos = saved\n"
    out += "        var i = 0\n"
    out += "        while i < n:\n"
    if ty.encoding == ENC_INTKEYS:
        out += "            var key = r.read_int_key()\n"
        out += "            if not key:\n"
        out += "                r.skip_value()\n"
        out += "                i += 1\n"
        out += "                continue\n"
        out += "            var k = key.value()\n"
    else:
        out += "            if not r.peek_is_str():\n"
        out += "                r.skip_value()\n"
        out += "                r.skip_value()\n"
        out += "                i += 1\n"
        out += "                continue\n"
        out += "            var key = r.read_str()\n"
    var first = True
    var j = 0
    while j < len(ty.props):
        var p = ty.props[j].copy()
        var fname = mojo_ident(p.name)
        var cond: String
        if ty.encoding == ENC_INTKEYS:
            cond = "k == Int64(" + String(p.int_key) + ")"
        else:
            cond = "key == \"" + p.name + "\""
        if first:
            out += "            if " + cond + ":\n"
            first = False
        else:
            out += "            elif " + cond + ":\n"
        var opt = _is_optional(doc, p.type_id)
        if opt:
            out += "                if r.peek_is_nil():\n"
            out += "                    r.read_nil()\n"
            out += "                    self." + fname + " = None\n"
            out += "                else:\n"
            out += "                    " + _dec_stmt(doc, p.type_id, "self." + fname, scc, self_id, "                    ") + "\n"
        else:
            out += "                " + _dec_stmt(doc, p.type_id, "self." + fname, scc, self_id, "                ") + "\n"
        j += 1
    if len(ty.props) == 0:
        out += "            r.skip_value()\n"
    else:
        out += "            else:\n"
        out += "                r.skip_value()\n"
    out += "            i += 1\n"
    if ty.encoding == ENC_MAP:
        out = _emit_expected_decode(doc, ty, scc, self_id) + out
    return out


def _emit_expected_decode(
    doc: SchemaDoc, ty: SchemaType, scc: List[Int], self_id: Int
) -> String:
    var out = String()
    out += "\n    def _decode_expected[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError -> Bool:\n"
    var i = 0
    while i < len(ty.props):
        var p = ty.props[i].copy()
        var fname = mojo_ident(p.name)
        if p.name.byte_length() <= 31:
            out += (
                "        if not r.try_eat_fixstr(\""
                + p.name
                + "\".as_bytes()):\n            return False\n"
            )
        else:
            out += (
                "        if not r.peek_is_str():\n            return False\n"
                + "        if r.read_str() != \""
                + p.name
                + "\":\n            return False\n"
            )
        var opt = _is_optional(doc, p.type_id)
        if opt:
            out += "        if r.peek_is_nil():\n"
            out += "            r.read_nil()\n"
            out += "            self." + fname + " = None\n"
            out += "        else:\n"
            out += (
                "            "
                + _dec_stmt(doc, p.type_id, "self." + fname, scc, self_id, "            ")
                + "\n"
            )
        else:
            out += (
                "        "
                + _dec_stmt(doc, p.type_id, "self." + fname, scc, self_id, "        ")
                + "\n"
            )
        i += 1
    out += "        return True\n"
    return out



def _dec_stmt(
    doc: SchemaDoc, tid: Int, acc: String, scc: List[Int], self_id: Int, indent: String = "        "
) -> String:
    var t = doc.types[tid].copy()
    if t.kind == ST_OPTIONAL:
        return _dec_stmt(doc, t.inner, acc, scc, self_id, indent)
    if t.kind == ST_REF or t.kind == ST_ENUM or t.kind == ST_CONST:
        return _dec_stmt(doc, t.inner, acc, scc, self_id, indent)
    if t.kind == ST_BOOL:
        return acc + " = r.read_bool()"
    if t.kind == ST_INT:
        return acc + " = r.read_i64()"
    if t.kind == ST_NUMBER:
        return acc + " = r.read_as_f64()"
    if t.kind == ST_STRING:
        return acc + " = r.read_str()"
    if t.kind == ST_BYTES:
        return acc + " = r.read_bin()"
    if t.kind == ST_TIMESTAMP:
        return (
            "var _ts = r.read_timestamp()\n"
            + indent
            + acc
            + " = MsgpackTimestamp(_ts[0], _ts[1])"
        )
    if t.kind == ST_EXT:
        return (
            "var _e = r.read_ext()\n" + indent + acc + " = MsgpackExt(_e[0], _e[1])"
        )
    if t.kind == ST_ARRAY:
        return _dec_list_block(doc, t.inner, acc, scc, self_id, indent)
    var tn = _type_name(doc, tid, scc, self_id)
    if _starts(tn, "Box["):
        var inner = _inner(tn)
        return (
            "var _c = "
            + inner
            + "()\n"
            + indent
            + "_c.decode_from(r)\n"
            + indent
            + acc
            + " = Box["
            + inner
            + "](_c^)"
        )
    return acc + " = " + tn + "()\n" + indent + acc + ".decode_from(r)"


def _dec_list_block(
    doc: SchemaDoc,
    tid: Int,
    acc: String,
    scc: List[Int],
    self_id: Int,
    indent: String,
) -> String:
    var elem = _type_name(doc, tid, scc, -1)
    var out = String()
    out += "var _ln = r.read_array_header()\n"
    out += indent + acc + " = List[" + elem + "](capacity=_ln)\n"
    out += indent + "var _j = 0\n"
    out += indent + "while _j < _ln:\n"
    var inner = doc.types[tid].copy()
    while inner.kind == ST_REF or inner.kind == ST_OPTIONAL or inner.kind == ST_ENUM or inner.kind == ST_CONST:
        if inner.inner < 0:
            break
        inner = doc.types[inner.inner].copy()
    var body = indent + "    "
    if inner.kind == ST_NUMBER:
        out += body + acc + ".append(r.read_as_f64())\n"
    elif inner.kind == ST_STRING:
        out += body + acc + ".append(r.read_str())\n"
    elif inner.kind == ST_INT:
        out += body + acc + ".append(r.read_i64())\n"
    elif inner.kind == ST_BOOL:
        out += body + acc + ".append(r.read_bool())\n"
    else:
        out += body + "var _it = " + elem + "()\n"
        out += body + "_it.decode_from(r)\n"
        out += body + acc + ".append(_it^)\n"
    out += body + "_j += 1"
    return out


def _emit_union(
    doc: SchemaDoc, ty: SchemaType, name: String, scc: List[Int], tid: Int
) raises DecodeError -> String:
    var out = String()
    out += "struct " + name + "(Copyable, Movable, Defaultable, Deinitable, MsgpackDatum):\n"
    out += "    var tag: Int\n"
    var i = 0
    while i < len(ty.branch_ids):
        var bn = _type_name(doc, ty.branch_ids[i], scc, tid)
        out += "    var b" + String(i) + ": " + bn + "\n"
        i += 1
    out += "\n    def __init__(out self):\n"
    out += "        self.tag = 0\n"
    i = 0
    while i < len(ty.branch_ids):
        var bn = _type_name(doc, ty.branch_ids[i], scc, tid)
        out += "        self.b" + String(i) + " = " + _zero(bn) + "\n"
        i += 1
    out += "\n    def encoded_len(self, options: EncodeOptions) -> Int:\n"
    out += "        if self.tag == 0:\n"
    out += "            return self.b0.encoded_len(options)\n"
    i = 1
    while i < len(ty.branch_ids):
        out += "        if self.tag == " + String(i) + ":\n"
        out += "            return self.b" + String(i) + ".encoded_len(options)\n"
        i += 1
    out += "        return 1\n"
    out += "\n    def encode_to(self, mut w: WireWriter, options: EncodeOptions):\n"
    i = 0
    while i < len(ty.branch_ids):
        if i == 0:
            out += "        if self.tag == 0:\n"
        else:
            out += "        elif self.tag == " + String(i) + ":\n"
        out += "            self.b" + String(i) + ".encode_to(w, options)\n"
        i += 1
    out += "\n    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:\n"
    out += "        raise DecodeError(DecodeError.KIND_TYPE, r.position())\n"
    return out
