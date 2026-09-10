from codegen.names import mojo_ident


def main() raises:
    if mojo_ident("struct") != "struct_":
        raise Error("struct")
    if mojo_ident("fn") != "fn_":
        raise Error("fn")
    if mojo_ident("ok") != "ok":
        raise Error("ok")
    print("test_codegen_names ok")
