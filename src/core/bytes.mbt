///|
pub struct ByteBuffer {
  data : Array[Byte]
}

///|
pub fn ByteBuffer::new() -> ByteBuffer {
  { data: [] }
}

///|
pub fn ByteBuffer::push(self : ByteBuffer, byte : Byte) -> Unit {
  self.data.push(byte)
}

///|
pub fn ByteBuffer::extend(self : ByteBuffer, bytes : Array[Byte]) -> Unit {
  for byte in bytes {
    self.data.push(byte)
  }
}

///|
pub fn ByteBuffer::to_array(self : ByteBuffer) -> Array[Byte] {
  self.data
}
