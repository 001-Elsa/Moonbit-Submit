pub enum DecodeError {
  UnexpectedEof
  MalformedVarint
  InvalidWireType(Int)
  NegativeLength
  Utf8Error
}

pub enum EncodeError {
  InvalidFieldNumber(Int)
}
