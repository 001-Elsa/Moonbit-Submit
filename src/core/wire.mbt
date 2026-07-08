///|
pub(all) enum WireType {
  Varint
  Fixed64
  LengthDelimited
}

///|
pub struct FieldKey {
  number : Int
  wire_type : WireType
}

///|
pub fn wire_type_to_int(wire_type : WireType) -> Int {
  match wire_type {
    Varint => 0
    Fixed64 => 1
    LengthDelimited => 2
  }
}

///|
pub fn int_to_wire_type(value : Int) -> Result[WireType, DecodeError] {
  match value {
    0 => Ok(Varint)
    1 => Ok(Fixed64)
    2 => Ok(LengthDelimited)
    _ => Err(InvalidWireType(value))
  }
}

///|
pub fn write_key(
  writer : Writer,
  number : Int,
  wire_type : WireType,
) -> Result[Unit, EncodeError] {
  if number <= 0 {
    Err(InvalidFieldNumber(number))
  } else {
    let raw = ((number << 3) | wire_type_to_int(wire_type)).to_int64()
    write_varint(writer, raw)
    Ok(())
  }
}

///|
pub fn read_key(reader : Reader) -> Result[FieldKey, DecodeError] {
  match read_varint(reader) {
    Ok(raw) => {
      let wire = (raw & 0x7L).to_int()
      let number = (raw >> 3).to_int()
      match int_to_wire_type(wire) {
        Ok(wire_type) => Ok({ number, wire_type })
        Err(err) => Err(err)
      }
    }
    Err(err) => Err(err)
  }
}

///|
pub fn write_length_delimited(writer : Writer, bytes : Array[Byte]) -> Unit {
  write_varint(writer, bytes.length().to_int64())
  writer.write_bytes(bytes)
}

///|
pub fn read_length_delimited(
  reader : Reader,
) -> Result[Array[Byte], DecodeError] {
  match read_varint(reader) {
    Ok(len) => reader.read_bytes(len.to_int())
    Err(err) => Err(err)
  }
}

///|
pub fn skip_field(
  reader : Reader,
  wire_type : WireType,
) -> Result[Unit, DecodeError] {
  match wire_type {
    Varint =>
      match read_varint(reader) {
        Ok(_) => Ok(())
        Err(err) => Err(err)
      }
    Fixed64 => reader.skip(8)
    LengthDelimited =>
      match read_varint(reader) {
        Ok(len) => reader.skip(len.to_int())
        Err(err) => Err(err)
      }
  }
}
