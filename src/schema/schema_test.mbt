test "parse auth schema" {
  let text = "package demo.auth\nmessage User { 1: id Int64 2: name String }\n"
  match parse_schema(text) {
    Ok(schema) => inspect(schema.package_name, content="demo.auth")
    Err(_) => fail("schema should parse")
  }
}

test "validate duplicate fields" {
  let text = "package demo\nmessage User { 1: id Int64 1: name String }\n"
  match parse_schema(text) {
    Err(_) => fail("schema should parse before validation")
    Ok(schema) => match validate_schema(schema) {
      Ok(_) => fail("schema should fail validation")
      Err(_) => ()
    }
  }
}

test "validate reserved field number" {
  let text = "package demo\nmessage User { reserved 1 1: id Int64 }\n"
  match parse_schema(text) {
    Err(_) => fail("schema should parse before validation")
    Ok(schema) => match validate_schema(schema) {
      Ok(_) => fail("schema should reject reserved field number")
      Err(err) => inspect(parse_error_to_string(err), content="2:27: field number 1 is reserved in message User")
    }
  }
}

test "validate reserved field range" {
  let text = "package demo\nmessage User { reserved 10..20 11: id Int64 }\n"
  match parse_schema(text) {
    Err(_) => fail("schema should parse reserved range")
    Ok(schema) => match validate_schema(schema) {
      Ok(_) => fail("schema should reject field number in reserved range")
      Err(_) => ()
    }
  }
}

test "compatible schema can reserve removed fields" {
  let old_text = "package demo\nmessage Save { 1: id String 2: score Int }\nenum State { 0: Unknown 1: Active }\n"
  let new_text = "package demo\nmessage Save { reserved 2 1: id String 3: title String }\nenum State { reserved 1 0: Unknown 2: Disabled }\n"
  match (parse_schema(old_text), parse_schema(new_text)) {
    (Ok(old_schema), Ok(new_schema)) => match check_compatible(old_schema, new_schema) {
      Ok(_) => ()
      Err(_) => fail("schema should be compatible")
    }
    _ => fail("schemas should parse")
  }
}

test "compatibility rejects removed unreserved fields" {
  let old_text = "package demo\nmessage Save { 1: id String 2: score Int }\n"
  let new_text = "package demo\nmessage Save { 1: id String }\n"
  match (parse_schema(old_text), parse_schema(new_text)) {
    (Ok(old_schema), Ok(new_schema)) => match check_compatible(old_schema, new_schema) {
      Ok(_) => fail("schema should be incompatible")
      Err(_) => ()
    }
    _ => fail("schemas should parse")
  }
}

test "parse deprecated field marker" {
  let text = "package demo\nmessage Save { 1: id String 2: old_score Int deprecated }\n"
  match parse_schema(text) {
    Ok(schema) => match schema.declarations[0] {
      Message(msg) => inspect(msg.fields[1].deprecated, content="true")
      _ => fail("schema should contain a message")
    }
    Err(_) => fail("schema should parse deprecated field marker")
  }
}

test "compatibility allows newly deprecated field" {
  let old_text = "package demo\nmessage Save { 1: id String 2: score Int }\n"
  let new_text = "package demo\nmessage Save { 1: id String 2: score Int deprecated }\n"
  match (parse_schema(old_text), parse_schema(new_text)) {
    (Ok(old_schema), Ok(new_schema)) => match check_compatible(old_schema, new_schema) {
      Ok(_) => ()
      Err(_) => fail("schema should allow adding deprecated marker")
    }
    _ => fail("schemas should parse")
  }
}

test "compatibility rejects deprecated marker removal" {
  let old_text = "package demo\nmessage Save { 1: id String 2: score Int deprecated }\n"
  let new_text = "package demo\nmessage Save { 1: id String 2: score Int }\n"
  match (parse_schema(old_text), parse_schema(new_text)) {
    (Ok(old_schema), Ok(new_schema)) => match check_compatible(old_schema, new_schema) {
      Ok(_) => fail("schema should reject deprecated marker removal")
      Err(_) => ()
    }
    _ => fail("schemas should parse")
  }
}
