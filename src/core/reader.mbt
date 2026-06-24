pub struct Reader {
  data : Array[Byte]
  mut offset : Int
}

pub fn Reader::new(data : Array[Byte]) -> Reader {
  { data, offset: 0 }
}

pub fn Reader::remaining(self : Reader) -> Int {
  self.data.length() - self.offset
}

pub fn Reader::is_empty(self : Reader) -> Bool {
  self.remaining() <= 0
}

pub fn Reader::read_byte(self : Reader) -> Result[Byte, DecodeError] {
  if self.offset >= self.data.length() {
    Err(UnexpectedEof)
  } else {
    let byte = self.data[self.offset]
    self.offset = self.offset + 1
    Ok(byte)
  }
}

pub fn Reader::read_bytes(self : Reader, len : Int) -> Result[Array[Byte], DecodeError] {
  if len < 0 {
    Err(NegativeLength)
  } else if self.offset + len > self.data.length() {
    Err(UnexpectedEof)
  } else {
    let out : Array[Byte] = []
    let end = self.offset + len
    while self.offset < end {
      out.push(self.data[self.offset])
      self.offset = self.offset + 1
    }
    Ok(out)
  }
}

pub fn Reader::skip(self : Reader, len : Int) -> Result[Unit, DecodeError] {
  if len < 0 {
    Err(NegativeLength)
  } else if self.offset + len > self.data.length() {
    Err(UnexpectedEof)
  } else {
    self.offset = self.offset + len
    Ok(())
  }
}
