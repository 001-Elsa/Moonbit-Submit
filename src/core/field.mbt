///|
fn write_key_or_abort(
  writer : Writer,
  number : Int,
  wire_type : WireType,
) -> Unit {
  match write_key(writer, number, wire_type) {
    Ok(_) => ()
    Err(_) => abort("invalid MoonPack field number")
  }
}

///|
pub fn write_bool_field(writer : Writer, number : Int, value : Bool) -> Unit {
  write_key_or_abort(writer, number, Varint)
  write_varint(writer, if value { 1L } else { 0L })
}

///|
pub fn write_int_field(writer : Writer, number : Int, value : Int) -> Unit {
  write_key_or_abort(writer, number, Varint)
  write_varint(writer, value.to_int64())
}

///|
pub fn write_int64_field(writer : Writer, number : Int, value : Int64) -> Unit {
  write_key_or_abort(writer, number, Varint)
  write_varint(writer, value)
}

///|
pub fn write_double_field(
  writer : Writer,
  number : Int,
  value : Double,
) -> Unit {
  write_key_or_abort(writer, number, Fixed64)
  let bits = value.reinterpret_as_int64()
  writer.write_byte((bits & 0xffL).to_byte())
  writer.write_byte(((bits >> 8) & 0xffL).to_byte())
  writer.write_byte(((bits >> 16) & 0xffL).to_byte())
  writer.write_byte(((bits >> 24) & 0xffL).to_byte())
  writer.write_byte(((bits >> 32) & 0xffL).to_byte())
  writer.write_byte(((bits >> 40) & 0xffL).to_byte())
  writer.write_byte(((bits >> 48) & 0xffL).to_byte())
  writer.write_byte(((bits >> 56) & 0xffL).to_byte())
}

///|
pub fn write_string_field(
  writer : Writer,
  number : Int,
  value : String,
) -> Unit {
  write_key_or_abort(writer, number, LengthDelimited)
  write_length_delimited(writer, @encoding.encode(UTF8, value).to_array())
}

///|
pub fn write_bytes_field(
  writer : Writer,
  number : Int,
  value : Array[Byte],
) -> Unit {
  write_key_or_abort(writer, number, LengthDelimited)
  write_length_delimited(writer, value)
}

///|
pub fn write_message_field(
  writer : Writer,
  number : Int,
  value : Array[Byte],
) -> Unit {
  write_bytes_field(writer, number, value)
}

///|
fn ensure_wire(
  actual : WireType,
  expected : WireType,
) -> Result[Unit, DecodeError] {
  if wire_type_to_int(actual) == wire_type_to_int(expected) {
    Ok(())
  } else {
    Err(InvalidWireType(wire_type_to_int(actual)))
  }
}

///|
pub fn read_bool_value(
  reader : Reader,
  wire_type : WireType,
) -> Result[Bool, DecodeError] {
  match ensure_wire(wire_type, Varint) {
    Err(err) => Err(err)
    Ok(_) =>
      match read_varint(reader) {
        Ok(value) => Ok(value != 0L)
        Err(err) => Err(err)
      }
  }
}

///|
pub fn read_int_value(
  reader : Reader,
  wire_type : WireType,
) -> Result[Int, DecodeError] {
  match ensure_wire(wire_type, Varint) {
    Err(err) => Err(err)
    Ok(_) =>
      match read_varint(reader) {
        Ok(value) => Ok(value.to_int())
        Err(err) => Err(err)
      }
  }
}

///|
pub fn read_int64_value(
  reader : Reader,
  wire_type : WireType,
) -> Result[Int64, DecodeError] {
  match ensure_wire(wire_type, Varint) {
    Err(err) => Err(err)
    Ok(_) => read_varint(reader)
  }
}

///|
pub fn read_double_value(
  reader : Reader,
  wire_type : WireType,
) -> Result[Double, DecodeError] {
  match ensure_wire(wire_type, Fixed64) {
    Err(err) => Err(err)
    Ok(_) =>
      match reader.read_bytes(8) {
        Err(err) => Err(err)
        Ok(bytes) => {
          let b0 = bytes[0].to_int64()
          let b1 = bytes[1].to_int64()
          let b2 = bytes[2].to_int64()
          let b3 = bytes[3].to_int64()
          let b4 = bytes[4].to_int64()
          let b5 = bytes[5].to_int64()
          let b6 = bytes[6].to_int64()
          let b7 = bytes[7].to_int64()
          let bits = b0 |
            (b1 << 8) |
            (b2 << 16) |
            (b3 << 24) |
            (b4 << 32) |
            (b5 << 40) |
            (b6 << 48) |
            (b7 << 56)
          Ok(bits.reinterpret_as_double())
        }
      }
  }
}

///|
pub fn read_string_value(
  reader : Reader,
  wire_type : WireType,
) -> Result[String, DecodeError] {
  match ensure_wire(wire_type, LengthDelimited) {
    Err(err) => Err(err)
    Ok(_) =>
      match read_length_delimited(reader) {
        Err(err) => Err(err)
        Ok(bytes) => {
          let decoder = @encoding.decoder(UTF8)
          let text = decoder.decode(Bytes::from_array(bytes)) catch {
            _ => return Err(Utf8Error)
          }
          Ok(text)
        }
      }
  }
}

///|
pub fn read_bytes_value(
  reader : Reader,
  wire_type : WireType,
) -> Result[Array[Byte], DecodeError] {
  match ensure_wire(wire_type, LengthDelimited) {
    Err(err) => Err(err)
    Ok(_) => read_length_delimited(reader)
  }
}

///|
pub fn read_message_value(
  reader : Reader,
  wire_type : WireType,
) -> Result[Array[Byte], DecodeError] {
  read_bytes_value(reader, wire_type)
}
