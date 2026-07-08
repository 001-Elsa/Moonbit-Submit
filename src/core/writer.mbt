///|
pub struct Writer {
  data : Array[Byte]
}

///|
pub fn Writer::new() -> Writer {
  { data: [] }
}

///|
pub fn Writer::write_byte(self : Writer, byte : Byte) -> Unit {
  self.data.push(byte)
}

///|
pub fn Writer::write_bytes(self : Writer, bytes : Array[Byte]) -> Unit {
  for byte in bytes {
    self.data.push(byte)
  }
}

///|
pub fn Writer::finish(self : Writer) -> Array[Byte] {
  self.data
}
