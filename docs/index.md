# mojo-messagepack

mojo-messagepack is a [MessagePack](https://msgpack.org/) serializer written in
[Mojo](https://www.modular.com/mojo). The runtime and the code generator are
Mojo. They do not wrap msgpack-c or any other C, C++, or Rust MessagePack
library.

<div class="grid cards" markdown="1">

-   __Why MessagePack__

    ---

    What MessagePack is, how type bytes work, how `str` differs from `bin`,
    and how maps, extensions, timestamps, and streams fit together.

    [:octicons-arrow-right-24: Read Why MessagePack](why-messagepack.md)

-   __Instructions__

    ---

    Install Mojo 1.0.0 with pixi, write a JSON Schema, generate Mojo, run the
    tests, and publish this site.

    [:octicons-arrow-right-24: Open Instructions](instructions.md)

-   __Examples__

    ---

    Encode and decode generated types, `MsgpackValue`, timestamps, and
    concatenated objects.

    [:octicons-arrow-right-24: See Examples](examples.md)

-   __Techniques__

    ---

    How encode and decode work: pre-sized writes, 256-way type dispatch,
    memcpy of `str`/`bin`, expected-order keys, and which ideas were measured
    and dropped.

    [:octicons-arrow-right-24: Read Techniques](techniques.md)

-   __Test data__

    ---

    What lives under `testdata/` (schemas, oracle bytes, fail-path goldens)
    and why each file is there.

    [:octicons-arrow-right-24: Read Test data](test-data.md)

</div>
