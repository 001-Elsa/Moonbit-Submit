pub struct Lexer {
  input : String
  mut index : Int
  mut line : Int
  mut column : Int
}

pub fn Lexer::new(input : String) -> Lexer {
  { input, index: 0, line: 1, column: 1 }
}

fn is_alpha_code(code : Int) -> Bool {
  (code >= 97 && code <= 122) || (code >= 65 && code <= 90) || code == 95
}

fn is_digit_code(code : Int) -> Bool {
  code >= 48 && code <= 57
}

fn is_alnum_code(code : Int) -> Bool {
  is_alpha_code(code) || is_digit_code(code)
}

fn peek(lx : Lexer) -> Int? {
  if lx.index >= lx.input.length() {
    None
  } else {
    Some(lx.input[lx.index].to_int())
  }
}

fn bump(lx : Lexer) -> Unit {
  match peek(lx) {
    Some(10) => {
      lx.index = lx.index + 1
      lx.line = lx.line + 1
      lx.column = 1
    }
    Some(_) => {
      lx.index = lx.index + 1
      lx.column = lx.column + 1
    }
    None => ()
  }
}

fn skip_ws_and_comments(lx : Lexer) -> Unit {
  let mut done = false
  while !done {
    done = true
    while true {
      match peek(lx) {
        Some(32) | Some(9) | Some(13) | Some(10) => bump(lx)
        _ => break
      }
    }
    if lx.index + 1 < lx.input.length() &&
      lx.input[lx.index].to_int() == 47 &&
      lx.input[lx.index + 1].to_int() == 47 {
      while true {
        match peek(lx) {
          Some(10) => {
            bump(lx)
            break
          }
          Some(_) => bump(lx)
          None => break
        }
      }
      done = false
    }
  }
}

fn read_ident(lx : Lexer) -> String {
  let start = lx.index
  while true {
    match peek(lx) {
      Some(code) => {
        if is_alnum_code(code) {
          bump(lx)
        } else {
          break
        }
      }
      None => break
    }
  }
  lx.input[start:lx.index].to_owned()
}

fn read_number(lx : Lexer) -> Int {
  let mut value = 0
  while true {
    match peek(lx) {
      Some(code) => {
        if is_digit_code(code) {
          value = value * 10 + (code - 48)
          bump(lx)
        } else {
          break
        }
      }
      None => break
    }
  }
  value
}

pub fn Lexer::next(self : Lexer) -> Token {
  skip_ws_and_comments(self)
  let line = self.line
  let column = self.column
  match peek(self) {
    None => { kind: Eof, line, column }
    Some(123) => { bump(self); { kind: LBrace, line, column } }
    Some(125) => { bump(self); { kind: RBrace, line, column } }
    Some(91) => { bump(self); { kind: LBracket, line, column } }
    Some(93) => { bump(self); { kind: RBracket, line, column } }
    Some(58) => { bump(self); { kind: Colon, line, column } }
    Some(46) => { bump(self); { kind: Dot, line, column } }
    Some(63) => { bump(self); { kind: Question, line, column } }
    Some(code) => {
      if is_alpha_code(code) {
        let ident = read_ident(self)
        let kind = match ident {
          "package" => KeywordPackage
          "message" => KeywordMessage
          "enum" => KeywordEnum
          "reserved" => KeywordReserved
          _ => Ident(ident)
        }
        { kind, line, column }
      } else if is_digit_code(code) {
        let value = read_number(self)
        { kind: IntLit(value), line, column }
      } else {
        bump(self)
        { kind: Ident(self.input[self.index - 1:self.index].to_owned()), line, column }
      }
    }
  }
}

pub fn lex(input : String) -> Array[Token] {
  let lexer = Lexer::new(input)
  let tokens : Array[Token] = []
  while true {
    let token = lexer.next()
    tokens.push(token)
    match token.kind {
      Eof => break
      _ => ()
    }
  }
  tokens
}
