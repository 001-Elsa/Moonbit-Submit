pub struct Parser {
  tokens : Array[Token]
  mut index : Int
}

pub fn Parser::new(tokens : Array[Token]) -> Parser {
  { tokens, index: 0 }
}

fn current(p : Parser) -> Token {
  if p.index >= p.tokens.length() {
    { kind: Eof, line: 0, column: 0 }
  } else {
    p.tokens[p.index]
  }
}

fn advance(p : Parser) -> Token {
  let token = current(p)
  p.index = p.index + 1
  token
}

fn unexpected(token : Token) -> ParseError {
  match token.kind {
    Eof => UnexpectedEof(token.line, token.column)
    kind => UnexpectedToken(token_name(kind), token.line, token.column)
  }
}

fn expect_ident(p : Parser) -> Result[String, ParseError] {
  let token = advance(p)
  match token.kind {
    Ident(name) => Ok(name)
    _ => Err(unexpected(token))
  }
}

fn expect_int_token(p : Parser) -> Result[Token, ParseError] {
  let token = advance(p)
  match token.kind {
    IntLit(_) => Ok(token)
    _ => Err(unexpected(token))
  }
}

fn token_int(token : Token) -> Int {
  match token.kind {
    IntLit(value) => value
    _ => 0
  }
}

fn expect_kind(p : Parser, expected : String) -> Result[Unit, ParseError] {
  let token = advance(p)
  if token_name(token.kind) == expected {
    Ok(())
  } else {
    Err(unexpected(token))
  }
}

fn parse_package(p : Parser) -> Result[String, ParseError] {
  let token = advance(p)
  match token.kind {
    KeywordPackage => {
      match expect_ident(p) {
        Err(err) => Err(err)
        Ok(first) => {
          let mut name = first
          while true {
            match current(p).kind {
              Dot => {
                ignore(advance(p))
                match expect_ident(p) {
                  Ok(part) => name = name + "." + part
                  Err(err) => return Err(err)
                }
              }
              _ => break
            }
          }
          Ok(name)
        }
      }
    }
    _ => Err(unexpected(token))
  }
}

fn parse_type(p : Parser) -> Result[TypeRef, ParseError] {
  match expect_ident(p) {
    Err(err) => Err(err)
    Ok(name) => {
      if name == "List" {
        match expect_kind(p, "[") {
          Err(err) => Err(err)
          Ok(_) => match parse_type(p) {
            Err(err) => Err(err)
            Ok(inner) => match expect_kind(p, "]") {
              Ok(_) => Ok(ListType(inner))
              Err(err) => Err(err)
            }
          }
        }
      } else {
        match name {
          "Bool" => Ok(BoolType)
          "Int" => Ok(IntType)
          "Int64" => Ok(Int64Type)
          "Double" => Ok(DoubleType)
          "String" => Ok(StringType)
          "Bytes" => Ok(BytesType)
          _ => Ok(NamedType(name))
        }
      }
    }
  }
}

fn parse_reserved(p : Parser) -> Result[Array[Int], ParseError] {
  ignore(advance(p))
  match expect_int_token(p) {
    Ok(start_token) => {
      let start = token_int(start_token)
      match current(p).kind {
        Dot => {
          ignore(advance(p))
          match expect_kind(p, ".") {
            Err(err) => Err(err)
            Ok(_) => match expect_int_token(p) {
              Err(err) => Err(err)
              Ok(end_token) => {
                let end = token_int(end_token)
                if end < start {
                  Err(UnexpectedToken("reserved range end before start", end_token.line, end_token.column))
                } else {
                  let numbers : Array[Int] = []
                  let mut number = start
                  while number <= end {
                    numbers.push(number)
                    number = number + 1
                  }
                  Ok(numbers)
                }
              }
            }
          }
        }
        _ => Ok([start])
      }
    }
    Err(err) => Err(err)
  }
}

fn parse_field(p : Parser) -> Result[FieldDecl, ParseError] {
  match expect_int_token(p) {
    Err(err) => Err(err)
    Ok(number_token) => {
      let number = token_int(number_token)
      match expect_kind(p, ":") {
        Err(err) => Err(err)
        Ok(_) => match expect_ident(p) {
          Err(err) => Err(err)
          Ok(name) => match parse_type(p) {
            Err(err) => Err(err)
            Ok(ty) => {
              let optional = match current(p).kind {
                Question => {
                  ignore(advance(p))
                  true
                }
                _ => false
              }
              Ok({ number, name, ty, optional, line: number_token.line, column: number_token.column })
            }
          }
        }
      }
    }
  }
}

fn parse_message(p : Parser) -> Result[MessageDecl, ParseError] {
  let token = advance(p)
  match token.kind {
    KeywordMessage => match expect_ident(p) {
      Err(err) => Err(err)
      Ok(name) => match expect_kind(p, "{") {
        Err(err) => Err(err)
        Ok(_) => {
          let fields : Array[FieldDecl] = []
          let reserved_numbers : Array[Int] = []
          while true {
            match current(p).kind {
              RBrace => {
                ignore(advance(p))
                break
              }
              KeywordReserved => match parse_reserved(p) {
                Ok(numbers) => {
                  for number in numbers {
                    reserved_numbers.push(number)
                  }
                }
                Err(err) => return Err(err)
              }
              Eof => return Err(UnexpectedEof(current(p).line, current(p).column))
              _ => match parse_field(p) {
                Ok(field) => fields.push(field)
                Err(err) => return Err(err)
              }
            }
          }
          Ok({ name, fields, reserved_numbers })
        }
      }
    }
    _ => Err(unexpected(token))
  }
}

fn parse_enum_case(p : Parser) -> Result[EnumCase, ParseError] {
  match expect_int_token(p) {
    Err(err) => Err(err)
    Ok(number_token) => {
      let number = token_int(number_token)
      match expect_kind(p, ":") {
        Err(err) => Err(err)
        Ok(_) => match expect_ident(p) {
          Ok(name) => Ok({ number, name, line: number_token.line, column: number_token.column })
          Err(err) => Err(err)
        }
      }
    }
  }
}

fn parse_enum(p : Parser) -> Result[EnumDecl, ParseError] {
  let token = advance(p)
  match token.kind {
    KeywordEnum => match expect_ident(p) {
      Err(err) => Err(err)
      Ok(name) => match expect_kind(p, "{") {
        Err(err) => Err(err)
        Ok(_) => {
          let cases : Array[EnumCase] = []
          let reserved_numbers : Array[Int] = []
          while true {
            match current(p).kind {
              RBrace => {
                ignore(advance(p))
                break
              }
              KeywordReserved => match parse_reserved(p) {
                Ok(numbers) => {
                  for number in numbers {
                    reserved_numbers.push(number)
                  }
                }
                Err(err) => return Err(err)
              }
              Eof => return Err(UnexpectedEof(current(p).line, current(p).column))
              _ => match parse_enum_case(p) {
                Ok(item) => cases.push(item)
                Err(err) => return Err(err)
              }
            }
          }
          Ok({ name, cases, reserved_numbers })
        }
      }
    }
    _ => Err(unexpected(token))
  }
}

pub fn parse_tokens(tokens : Array[Token]) -> Result[Schema, ParseError] {
  let parser = Parser::new(tokens)
  match parse_package(parser) {
    Err(err) => Err(err)
    Ok(package_name) => {
      let declarations : Array[Decl] = []
      while true {
        match current(parser).kind {
          KeywordMessage => match parse_message(parser) {
            Ok(msg) => declarations.push(Message(msg))
            Err(err) => return Err(err)
          }
          KeywordEnum => match parse_enum(parser) {
            Ok(en) => declarations.push(Enum(en))
            Err(err) => return Err(err)
          }
          Eof => break
          _ => return Err(unexpected(current(parser)))
        }
      }
      Ok({ package_name, declarations })
    }
  }
}

pub fn parse_schema(input : String) -> Result[Schema, ParseError] {
  parse_tokens(lex(input))
}
