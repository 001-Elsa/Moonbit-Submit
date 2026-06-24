pub enum TokenKind {
  Ident(String)
  IntLit(Int)
  KeywordPackage
  KeywordMessage
  KeywordEnum
  KeywordReserved
  LBrace
  RBrace
  LBracket
  RBracket
  Colon
  Dot
  Question
  Eof
}

pub struct Token {
  kind : TokenKind
  line : Int
  column : Int
}

pub enum ParseError {
  UnexpectedToken(String, Int, Int)
  UnexpectedEof(Int, Int)
  DuplicateFieldNumber(String, Int, Int, Int)
  DuplicateFieldName(String, String, Int, Int)
  ReservedFieldNumber(String, Int, Int, Int)
  DuplicateEnumNumber(String, Int, Int, Int)
  DuplicateEnumName(String, String, Int, Int)
  ReservedEnumNumber(String, Int, Int, Int)
  UnknownType(String, Int, Int)
}

pub fn token_name(kind : TokenKind) -> String {
  match kind {
    Ident(name) => "identifier " + name
    IntLit(value) => "integer " + value.to_string()
    KeywordPackage => "package"
    KeywordMessage => "message"
    KeywordEnum => "enum"
    KeywordReserved => "reserved"
    LBrace => "{"
    RBrace => "}"
    LBracket => "["
    RBracket => "]"
    Colon => ":"
    Dot => "."
    Question => "?"
    Eof => "end of file"
  }
}

pub fn parse_error_to_string(err : ParseError) -> String {
  match err {
    UnexpectedToken(token, line, column) =>
      line.to_string() + ":" + column.to_string() + ": unexpected token: " + token
    UnexpectedEof(line, column) =>
      line.to_string() + ":" + column.to_string() + ": unexpected end of file"
    DuplicateFieldNumber(message, number, line, column) =>
      line.to_string() + ":" + column.to_string() + ": duplicate field number " + number.to_string() + " in message " + message
    DuplicateFieldName(message, name, line, column) =>
      line.to_string() + ":" + column.to_string() + ": duplicate field name " + name + " in message " + message
    ReservedFieldNumber(message, number, line, column) =>
      line.to_string() + ":" + column.to_string() + ": field number " + number.to_string() + " is reserved in message " + message
    DuplicateEnumNumber(en, number, line, column) =>
      line.to_string() + ":" + column.to_string() + ": duplicate enum number " + number.to_string() + " in enum " + en
    DuplicateEnumName(en, name, line, column) =>
      line.to_string() + ":" + column.to_string() + ": duplicate enum name " + name + " in enum " + en
    ReservedEnumNumber(en, number, line, column) =>
      line.to_string() + ":" + column.to_string() + ": enum number " + number.to_string() + " is reserved in enum " + en
    UnknownType(name, line, column) =>
      line.to_string() + ":" + column.to_string() + ": unknown type: " + name
  }
}
