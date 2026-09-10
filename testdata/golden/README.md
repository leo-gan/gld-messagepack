# Golden vectors

Success files come from `scripts/gen_golden.py` using Python
`msgpack.packb(..., use_bin_type=True)`. Fail-path files (`unused_c1`,
`truncated_uint8`, `bad_utf8_str`, `timestamp_len3`) are literal bytes
written by the same script. Do not hand-edit either set.
