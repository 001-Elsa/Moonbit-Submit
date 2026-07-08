///|
pub struct SourceWriter {
  mut text : String
  mut indent : Int
}

///|
pub fn SourceWriter::new() -> SourceWriter {
  { text: "", indent: 0 }
}

///|
pub fn SourceWriter::push_indent(self : SourceWriter) -> Unit {
  self.indent = self.indent + 1
}

///|
pub fn SourceWriter::pop_indent(self : SourceWriter) -> Unit {
  if self.indent > 0 {
    self.indent = self.indent - 1
  }
}

///|
pub fn SourceWriter::line(self : SourceWriter, value : String) -> Unit {
  let mut prefix = ""
  let mut i = 0
  while i < self.indent {
    prefix = prefix + "  "
    i = i + 1
  }
  self.text = self.text + prefix + value + "\n"
}

///|
pub fn SourceWriter::blank(self : SourceWriter) -> Unit {
  self.text = self.text + "\n"
}

///|
pub fn SourceWriter::finish(self : SourceWriter) -> String {
  self.text
}
