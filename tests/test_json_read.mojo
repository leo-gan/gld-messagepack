from schema.json_read import decode_json


def main() raises:
    var v = decode_json("{\"a\":\"x\\\"y\",\"n\":1}".as_bytes())
    if v.get("a").as_str() != "x\"y":
        raise Error("escape")
    if v.get("n").as_int() != Int64(1):
        raise Error("int")
    var fire = decode_json("{\"t\":\"🔥\"}".as_bytes())
    if fire.get("t").as_str() != "🔥":
        raise Error("fire")
    print("test_json_read ok")
