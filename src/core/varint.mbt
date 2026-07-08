///|
pub fn write_varint(writer : Writer, value : Int64) -> Unit {
  let mut n = value
  while n >= 0x80L {
    let byte = ((n & 0x7fL) | 0x80L).to_byte()
    writer.write_byte(byte)
    n = n >> 7
  }
  writer.write_byte(n.to_byte())
}

///|
pub fn read_varint(reader : Reader) -> Result[Int64, DecodeError] {
  let mut shift = 0
  let mut result = 0L
  while shift < 64 {
    match reader.read_byte() {
      Ok(byte) => {
        let b = byte.to_int64()
        result = result | ((b & 0x7fL) << shift)
        if (b & 0x80L) == 0L {
          return Ok(result)
        }
        shift = shift + 7
      }
      Err(err) => return Err(err)
    }
  }
  Err(MalformedVarint)
}

///|
pub fn encoded_varint_len(value : Int64) -> Int {
  let mut n = value
  let mut len = 1
  while n >= 0x80L {
    n = n >> 7
    len = len + 1
  }
  len
}
