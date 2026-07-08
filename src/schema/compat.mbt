fn compat_contains_int(values : Array[Int], value : Int) -> Bool {
  for item in values {
    if item == value {
      return true
    }
  }
  false
}

fn find_message(schema : Schema, name : String) -> MessageDecl? {
  for decl in schema.declarations {
    match decl {
      Message(msg) =>
        if msg.name == name {
          return Some(msg)
        }
      _ => ()
    }
  }
  None
}

fn find_enum(schema : Schema, name : String) -> EnumDecl? {
  for decl in schema.declarations {
    match decl {
      Enum(en) =>
        if en.name == name {
          return Some(en)
        }
      _ => ()
    }
  }
  None
}

fn find_field_by_number(msg : MessageDecl, number : Int) -> FieldDecl? {
  for field in msg.fields {
    if field.number == number {
      return Some(field)
    }
  }
  None
}

fn find_case_by_number(en : EnumDecl, number : Int) -> EnumCase? {
  for item in en.cases {
    if item.number == number {
      return Some(item)
    }
  }
  None
}

fn field_shape(field : FieldDecl) -> String {
  let suffix = if field.optional { "?" } else { "" }
  field.ty.display() + suffix
}

fn check_message_compatible(old_msg : MessageDecl, new_msg : MessageDecl) -> Result[Unit, String] {
  for old_field in old_msg.fields {
    match find_field_by_number(new_msg, old_field.number) {
      Some(new_field) => {
        if old_field.name != new_field.name {
          return Err("message " + old_msg.name + " field " + old_field.number.to_string() + " renamed from " + old_field.name + " to " + new_field.name)
        }
        if field_shape(old_field) != field_shape(new_field) {
          return Err("message " + old_msg.name + " field " + old_field.number.to_string() + " changed type from " + field_shape(old_field) + " to " + field_shape(new_field))
        }
        if old_field.deprecated && !new_field.deprecated {
          return Err("message " + old_msg.name + " field " + old_field.number.to_string() + " removed deprecated marker")
        }
      }
      None =>
        if !compat_contains_int(new_msg.reserved_numbers, old_field.number) {
          return Err("message " + old_msg.name + " removed field " + old_field.number.to_string() + " without reserving it")
        }
    }
  }
  Ok(())
}

fn check_enum_compatible(old_en : EnumDecl, new_en : EnumDecl) -> Result[Unit, String] {
  for old_case in old_en.cases {
    match find_case_by_number(new_en, old_case.number) {
      Some(new_case) =>
        if old_case.name != new_case.name {
          return Err("enum " + old_en.name + " tag " + old_case.number.to_string() + " renamed from " + old_case.name + " to " + new_case.name)
        }
      None =>
        if !compat_contains_int(new_en.reserved_numbers, old_case.number) {
          return Err("enum " + old_en.name + " removed tag " + old_case.number.to_string() + " without reserving it")
        }
    }
  }
  Ok(())
}

pub fn check_compatible(old_schema : Schema, new_schema : Schema) -> Result[Unit, String] {
  if old_schema.package_name != new_schema.package_name {
    return Err("package changed from " + old_schema.package_name + " to " + new_schema.package_name)
  }
  for decl in old_schema.declarations {
    match decl {
      Message(old_msg) => match find_message(new_schema, old_msg.name) {
        Some(new_msg) => match check_message_compatible(old_msg, new_msg) {
          Ok(_) => ()
          Err(err) => return Err(err)
        }
        None => return Err("message removed: " + old_msg.name)
      }
      Enum(old_en) => match find_enum(new_schema, old_en.name) {
        Some(new_en) => match check_enum_compatible(old_en, new_en) {
          Ok(_) => ()
          Err(err) => return Err(err)
        }
        None => return Err("enum removed: " + old_en.name)
      }
    }
  }
  Ok(())
}
