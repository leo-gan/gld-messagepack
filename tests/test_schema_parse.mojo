from schema.parse import parse_schema_file


def main() raises:
    var doc = parse_schema_file("testdata/schema/benchmark_v2.json")
    if doc.root_name != "Message":
        raise Error("title")
    if len(doc.def_names) != 7:
        raise Error("defs")
    print("test_schema_parse ok")
