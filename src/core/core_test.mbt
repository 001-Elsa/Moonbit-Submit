///|
test "varint encoded length" {
  inspect(encoded_varint_len(0L), content="1")
  inspect(encoded_varint_len(127L), content="1")
  inspect(encoded_varint_len(128L), content="2")
}

///|
test "wire key roundtrip" {
  let writer = Writer::new()
  match write_key(writer, 7, LengthDelimited) {
    Err(_) => fail("key should encode")
    Ok(_) => {
      let reader = Reader::new(writer.finish())
      match read_key(reader) {
        Err(_) => fail("key should decode")
        Ok(key) => {
          inspect(key.number, content="7")
          inspect(wire_type_to_int(key.wire_type), content="2")
        }
      }
    }
  }
}
