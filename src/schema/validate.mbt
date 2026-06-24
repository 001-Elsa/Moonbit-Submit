fn collect_decl_names(schema : Schema) -> Array[String] {
  let names : Array[String] = []
  for decl in schema.declarations {
    match decl {
      Message(msg) => names.push(msg.name)
      Enum(en) => names.push(en.name)
    }
  }
  names
}

fn contains_name(names : Array[String], name : String) -> Bool {
  for item in names {
    if item == name {
      return true
    }
  }
  false
}

fn contains_int(values : Array[Int], value : Int) -> Bool {
  for item in values {
    if item == value {
      return true
    }
  }
  false
}

fn validate_type(
  ty : TypeRef,
  names : Array[String],
  line : Int,
  column : Int,
) -> Result[Unit, ParseError] {
  match ty {
    NamedType(name) => {
      if contains_name(names, name) {
        Ok(())
      } else {
        Err(UnknownType(name, line, column))
      }
    }
    ListType(inner) => validate_type(inner, names, line, column)
    _ => Ok(())
  }
}

fn validate_message(msg : MessageDecl, names : Array[String]) -> Result[Unit, ParseError] {
  let field_numbers : Array[Int] = []
  let field_names : Array[String] = []
  for field in msg.fields {
    if contains_int(msg.reserved_numbers, field.number) {
      return Err(ReservedFieldNumber(msg.name, field.number, field.line, field.column))
    }
    for number in field_numbers {
      if number == field.number {
        return Err(DuplicateFieldNumber(msg.name, field.number, field.line, field.column))
      }
    }
    for name in field_names {
      if name == field.name {
        return Err(DuplicateFieldName(msg.name, field.name, field.line, field.column))
      }
    }
    field_numbers.push(field.number)
    field_names.push(field.name)
    match validate_type(field.ty, names, field.line, field.column) {
      Ok(_) => ()
      Err(err) => return Err(err)
    }
  }
  Ok(())
}

fn validate_enum(en : EnumDecl) -> Result[Unit, ParseError] {
  let numbers : Array[Int] = []
  let names : Array[String] = []
  for item in en.cases {
    if contains_int(en.reserved_numbers, item.number) {
      return Err(ReservedEnumNumber(en.name, item.number, item.line, item.column))
    }
    for number in numbers {
      if number == item.number {
        return Err(DuplicateEnumNumber(en.name, item.number, item.line, item.column))
      }
    }
    for name in names {
      if name == item.name {
        return Err(DuplicateEnumName(en.name, item.name, item.line, item.column))
      }
    }
    numbers.push(item.number)
    names.push(item.name)
  }
  Ok(())
}

pub fn validate_schema(schema : Schema) -> Result[Unit, ParseError] {
  let names = collect_decl_names(schema)
  for decl in schema.declarations {
    match decl {
      Message(msg) => match validate_message(msg, names) {
        Ok(_) => ()
        Err(err) => return Err(err)
      }
      Enum(en) => match validate_enum(en) {
        Ok(_) => ()
        Err(err) => return Err(err)
      }
    }
  }
  Ok(())
}

