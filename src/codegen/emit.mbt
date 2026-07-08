fn find_enum(schema : @schema.Schema, name : String) -> @schema.EnumDecl? {
  for decl in schema.declarations {
    match decl {
      @schema.Enum(en) =>
        if en.name == name {
          return Some(en)
        }
      _ => ()
    }
  }
  None
}

fn is_enum(schema : @schema.Schema, name : String) -> Bool {
  match find_enum(schema, name) {
    Some(_) => true
    None => false
  }
}

fn default_expr(schema : @schema.Schema, ty : @schema.TypeRef, optional : Bool) -> String {
  if optional {
    "None"
  } else {
    match ty {
      @schema.BoolType => "false"
      @schema.IntType => "0"
      @schema.Int64Type => "0L"
      @schema.DoubleType => "0.0"
      @schema.StringType => "\"\""
      @schema.BytesType => "[]"
      @schema.ListType(_) => "[]"
      @schema.NamedType(name) =>
        match find_enum(schema, name) {
          Some(en) =>
            if en.cases.length() > 0 {
              en.cases[0].name
            } else {
              abort("empty enum")
            }
          None => "default_" + snake_name(name) + "()"
        }
    }
  }
}

fn sample_expr(schema : @schema.Schema, ty : @schema.TypeRef, optional : Bool, field_name : String) -> String {
  if optional {
    match ty {
      @schema.StringType => "Some(\"sample_" + field_name + "\")"
      @schema.IntType => "Some(42)"
      @schema.Int64Type => "Some(42L)"
      @schema.DoubleType => "Some(3.5)"
      @schema.BoolType => "Some(true)"
      @schema.BytesType => "Some([b'a', b'b'])"
      @schema.NamedType(name) =>
        if is_enum(schema, name) {
          match find_enum(schema, name) {
            Some(en) =>
              if en.cases.length() > 1 {
                "Some(" + en.cases[1].name + ")"
              } else if en.cases.length() > 0 {
                "Some(" + en.cases[0].name + ")"
              } else {
                "None"
              }
            None => "None"
          }
        } else {
          "Some(sample_" + snake_name(name) + "())"
        }
      @schema.ListType(_) => "Some([])"
    }
  } else {
    match ty {
      @schema.BoolType => "true"
      @schema.IntType => "42"
      @schema.Int64Type => "42L"
      @schema.DoubleType => "3.5"
      @schema.StringType => "\"sample_" + field_name + "\""
      @schema.BytesType => "[b'a', b'b']"
      @schema.ListType(inner) => "[" + sample_expr(schema, inner, false, field_name) + "]"
      @schema.NamedType(name) =>
        if is_enum(schema, name) {
          match find_enum(schema, name) {
            Some(en) =>
              if en.cases.length() > 1 {
                en.cases[1].name
              } else if en.cases.length() > 0 {
                en.cases[0].name
              } else {
                abort("empty enum")
              }
            None => abort("missing enum")
          }
        } else {
          "sample_" + snake_name(name) + "()"
        }
    }
  }
}

fn emit_enum(writer : SourceWriter, en : @schema.EnumDecl) -> Unit {
  writer.line("pub enum " + en.name + " {")
  writer.push_indent()
  for item in en.cases {
    writer.line(item.name)
  }
  writer.pop_indent()
  writer.line("}")
  writer.blank()
  let lower = snake_name(en.name)
  writer.line("pub fn " + lower + "_to_int(value : " + en.name + ") -> Int {")
  writer.push_indent()
  writer.line("match value {")
  writer.push_indent()
  for item in en.cases {
    writer.line(item.name + " => " + item.number.to_string())
  }
  writer.pop_indent()
  writer.line("}")
  writer.pop_indent()
  writer.line("}")
  writer.blank()
  writer.line("pub fn " + lower + "_from_int(value : Int) -> " + en.name + " {")
  writer.push_indent()
  writer.line("match value {")
  writer.push_indent()
  for item in en.cases {
    writer.line(item.number.to_string() + " => " + item.name)
  }
  if en.cases.length() > 0 {
    writer.line("_ => " + en.cases[0].name)
  }
  writer.pop_indent()
  writer.line("}")
  writer.pop_indent()
  writer.line("}")
  writer.blank()
}

fn emit_struct(writer : SourceWriter, msg : @schema.MessageDecl) -> Unit {
  writer.line("pub struct " + msg.name + " {")
  writer.push_indent()
  for field in msg.fields {
    writer.line(field.name + " : " + moonbit_type_name(field.ty, field.optional))
  }
  writer.pop_indent()
  writer.line("}")
  writer.blank()
}

fn emit_value_equal_guard(
  writer : SourceWriter,
  schema : @schema.Schema,
  ty : @schema.TypeRef,
  lhs : String,
  rhs : String,
) -> Unit {
  match ty {
    @schema.NamedType(name) =>
      if is_enum(schema, name) {
        writer.line("if " + lhs + " != " + rhs + " {")
      } else {
        writer.line("if !equal_" + snake_name(name) + "(" + lhs + ", " + rhs + ") {")
      }
    _ => writer.line("if " + lhs + " != " + rhs + " {")
  }
  writer.push_indent()
  writer.line("return false")
  writer.pop_indent()
  writer.line("}")
}

fn emit_list_equal_guard(
  writer : SourceWriter,
  schema : @schema.Schema,
  field : @schema.FieldDecl,
  inner : @schema.TypeRef,
) -> Unit {
  writer.line("if lhs." + field.name + ".length() != rhs." + field.name + ".length() {")
  writer.push_indent()
  writer.line("return false")
  writer.pop_indent()
  writer.line("}")
  let index = "i_" + snake_name(field.name)
  writer.line("let mut " + index + " = 0")
  writer.line("while " + index + " < lhs." + field.name + ".length() {")
  writer.push_indent()
  emit_value_equal_guard(
    writer,
    schema,
    inner,
    "lhs." + field.name + "[" + index + "]",
    "rhs." + field.name + "[" + index + "]",
  )
  writer.line(index + " = " + index + " + 1")
  writer.pop_indent()
  writer.line("}")
}

fn emit_optional_equal_guard(
  writer : SourceWriter,
  schema : @schema.Schema,
  field : @schema.FieldDecl,
) -> Unit {
  writer.line("match lhs." + field.name + " {")
  writer.push_indent()
  writer.line("None => match rhs." + field.name + " {")
  writer.push_indent()
  writer.line("None => ()")
  writer.line("_ => return false")
  writer.pop_indent()
  writer.line("}")
  writer.line("Some(left) => match rhs." + field.name + " {")
  writer.push_indent()
  writer.line("Some(right) => {")
  writer.push_indent()
  emit_value_equal_guard(writer, schema, field.ty, "left", "right")
  writer.pop_indent()
  writer.line("}")
  writer.line("_ => return false")
  writer.pop_indent()
  writer.line("}")
  writer.pop_indent()
  writer.line("}")
}

fn emit_equal_fn(writer : SourceWriter, schema : @schema.Schema, msg : @schema.MessageDecl) -> Unit {
  let lower = snake_name(msg.name)
  writer.line("pub fn equal_" + lower + "(lhs : " + msg.name + ", rhs : " + msg.name + ") -> Bool {")
  writer.push_indent()
  for field in msg.fields {
    match field.ty {
      @schema.ListType(inner) => emit_list_equal_guard(writer, schema, field, inner)
      _ =>
        if field.optional {
          emit_optional_equal_guard(writer, schema, field)
        } else {
          emit_value_equal_guard(writer, schema, field.ty, "lhs." + field.name, "rhs." + field.name)
        }
    }
  }
  writer.line("true")
  writer.pop_indent()
  writer.line("}")
  writer.blank()
}

fn encode_call(schema : @schema.Schema, number : Int, ty : @schema.TypeRef, expr : String) -> String {
  match ty {
    @schema.BoolType => "@core.write_bool_field(writer, " + number.to_string() + ", " + expr + ")"
    @schema.IntType => "@core.write_int_field(writer, " + number.to_string() + ", " + expr + ")"
    @schema.Int64Type => "@core.write_int64_field(writer, " + number.to_string() + ", " + expr + ")"
    @schema.DoubleType => "@core.write_double_field(writer, " + number.to_string() + ", " + expr + ")"
    @schema.StringType => "@core.write_string_field(writer, " + number.to_string() + ", " + expr + ")"
    @schema.BytesType => "@core.write_bytes_field(writer, " + number.to_string() + ", " + expr + ")"
    @schema.NamedType(name) =>
      if is_enum(schema, name) {
        "@core.write_int_field(writer, " + number.to_string() + ", " + snake_name(name) + "_to_int(" + expr + "))"
      } else {
        "@core.write_message_field(writer, " + number.to_string() + ", encode_" + snake_name(name) + "(" + expr + "))"
      }
    @schema.ListType(_) => abort("list encode should use inner type")
  }
}

fn encode_inner_call(schema : @schema.Schema, number : Int, ty : @schema.TypeRef, expr : String) -> String {
  encode_call(schema, number, ty, expr)
}

fn emit_encode_field(writer : SourceWriter, schema : @schema.Schema, field : @schema.FieldDecl) -> Unit {
  match field.ty {
    @schema.ListType(inner) => {
      writer.line("for item in value." + field.name + " {")
      writer.push_indent()
      writer.line(encode_inner_call(schema, field.number, inner, "item"))
      writer.pop_indent()
      writer.line("}")
    }
    _ =>
      if field.optional {
        writer.line("match value." + field.name + " {")
        writer.push_indent()
        writer.line("Some(v) => " + encode_call(schema, field.number, field.ty, "v"))
        writer.line("None => ()")
        writer.pop_indent()
        writer.line("}")
      } else {
        writer.line(encode_call(schema, field.number, field.ty, "value." + field.name))
      }
  }
}

fn decode_value_call(schema : @schema.Schema, ty : @schema.TypeRef) -> String {
  match ty {
    @schema.BoolType => "@core.read_bool_value(reader, key.wire_type)"
    @schema.IntType => "@core.read_int_value(reader, key.wire_type)"
    @schema.Int64Type => "@core.read_int64_value(reader, key.wire_type)"
    @schema.DoubleType => "@core.read_double_value(reader, key.wire_type)"
    @schema.StringType => "@core.read_string_value(reader, key.wire_type)"
    @schema.BytesType => "@core.read_bytes_value(reader, key.wire_type)"
    @schema.NamedType(name) =>
      if is_enum(schema, name) {
        "@core.read_int_value(reader, key.wire_type)"
      } else {
        "@core.read_message_value(reader, key.wire_type)"
      }
    @schema.ListType(_) => abort("list decode should use inner type")
  }
}

fn emit_decode_assign(
  writer : SourceWriter,
  schema : @schema.Schema,
  target : String,
  ty : @schema.TypeRef,
) -> Unit {
  writer.line("match " + decode_value_call(schema, ty) + " {")
  writer.push_indent()
  writer.line("Err(err) => return Err(err)")
  match ty {
    @schema.NamedType(name) =>
      if is_enum(schema, name) {
        writer.line("Ok(v) => " + target + " = " + snake_name(name) + "_from_int(v)")
      } else {
        writer.line("Ok(bytes) => match decode_" + snake_name(name) + "(bytes) {")
        writer.push_indent()
        writer.line("Ok(v) => " + target + " = v")
        writer.line("Err(err) => return Err(err)")
        writer.pop_indent()
        writer.line("}")
      }
    _ => writer.line("Ok(v) => " + target + " = v")
  }
  writer.pop_indent()
  writer.line("}")
}

fn emit_decode_field(writer : SourceWriter, schema : @schema.Schema, field : @schema.FieldDecl) -> Unit {
  match field.ty {
    @schema.ListType(inner) => {
      writer.line("match " + decode_value_call(schema, inner) + " {")
      writer.push_indent()
      writer.line("Err(err) => return Err(err)")
      match inner {
        @schema.NamedType(name) =>
          if is_enum(schema, name) {
            writer.line("Ok(v) => " + field.name + ".push(" + snake_name(name) + "_from_int(v))")
          } else {
            writer.line("Ok(bytes) => match decode_" + snake_name(name) + "(bytes) {")
            writer.push_indent()
            writer.line("Ok(v) => " + field.name + ".push(v)")
            writer.line("Err(err) => return Err(err)")
            writer.pop_indent()
            writer.line("}")
          }
        _ => writer.line("Ok(v) => " + field.name + ".push(v)")
      }
      writer.pop_indent()
      writer.line("}")
    }
    _ =>
      if field.optional {
        writer.line("match " + decode_value_call(schema, field.ty) + " {")
        writer.push_indent()
        writer.line("Err(err) => return Err(err)")
        match field.ty {
          @schema.NamedType(name) =>
            if is_enum(schema, name) {
              writer.line("Ok(v) => " + field.name + " = Some(" + snake_name(name) + "_from_int(v))")
            } else {
              writer.line("Ok(bytes) => match decode_" + snake_name(name) + "(bytes) {")
              writer.push_indent()
              writer.line("Ok(v) => " + field.name + " = Some(v)")
              writer.line("Err(err) => return Err(err)")
              writer.pop_indent()
              writer.line("}")
            }
          _ => writer.line("Ok(v) => " + field.name + " = Some(v)")
        }
        writer.pop_indent()
        writer.line("}")
      } else {
        emit_decode_assign(writer, schema, field.name, field.ty)
      }
  }
}

fn emit_message_codec(writer : SourceWriter, schema : @schema.Schema, msg : @schema.MessageDecl) -> Unit {
  let lower = snake_name(msg.name)
  writer.line("pub fn default_" + lower + "() -> " + msg.name + " {")
  writer.push_indent()
  writer.line("{")
  writer.push_indent()
  for field in msg.fields {
    writer.line(field.name + ": " + default_expr(schema, field.ty, field.optional) + ",")
  }
  writer.pop_indent()
  writer.line("}")
  writer.pop_indent()
  writer.line("}")
  writer.blank()
  writer.line("pub fn sample_" + lower + "() -> " + msg.name + " {")
  writer.push_indent()
  writer.line("{")
  writer.push_indent()
  for field in msg.fields {
    writer.line(field.name + ": " + sample_expr(schema, field.ty, field.optional, field.name) + ",")
  }
  writer.pop_indent()
  writer.line("}")
  writer.pop_indent()
  writer.line("}")
  writer.blank()
  emit_equal_fn(writer, schema, msg)
  writer.line("pub fn encode_" + lower + "(value : " + msg.name + ") -> Array[Byte] {")
  writer.push_indent()
  writer.line("let writer = @core.Writer::new()")
  for field in msg.fields {
    emit_encode_field(writer, schema, field)
  }
  writer.line("writer.finish()")
  writer.pop_indent()
  writer.line("}")
  writer.blank()
  writer.line("pub fn decode_" + lower + "(input : Array[Byte]) -> Result[" + msg.name + ", @core.DecodeError] {")
  writer.push_indent()
  writer.line("let reader = @core.Reader::new(input)")
  for field in msg.fields {
    let binding = match field.ty {
      @schema.ListType(_) => "let "
      _ => "let mut "
    }
    writer.line(binding + field.name + " : " + moonbit_type_name(field.ty, field.optional) + " = " + default_expr(schema, field.ty, field.optional))
  }
  writer.line("while !reader.is_empty() {")
  writer.push_indent()
  writer.line("match @core.read_key(reader) {")
  writer.push_indent()
  writer.line("Err(err) => return Err(err)")
  writer.line("Ok(key) => match key.number {")
  writer.push_indent()
  for field in msg.fields {
    writer.line(field.number.to_string() + " => {")
    writer.push_indent()
    emit_decode_field(writer, schema, field)
    writer.pop_indent()
    writer.line("}")
  }
  writer.line("_ => match @core.skip_field(reader, key.wire_type) {")
  writer.push_indent()
  writer.line("Ok(_) => ()")
  writer.line("Err(err) => return Err(err)")
  writer.pop_indent()
  writer.line("}")
  writer.pop_indent()
  writer.line("}")
  writer.pop_indent()
  writer.line("}")
  writer.pop_indent()
  writer.line("}")
  writer.line("Ok({")
  writer.push_indent()
  for field in msg.fields {
    writer.line(field.name + ",")
  }
  writer.pop_indent()
  writer.line("})")
  writer.pop_indent()
  writer.line("}")
  writer.blank()
}

fn emit_header(writer : SourceWriter) -> Unit {
  writer.line("// Generated by MoonPack. Do not edit by hand.")
  writer.line("// Package importing this file should import local/moonpack/src/core as @core.")
  writer.blank()
}

fn yes_no(value : Bool) -> String {
  if value {
    "yes"
  } else {
    "no"
  }
}

fn field_type_display(field : @schema.FieldDecl) -> String {
  let suffix = if field.optional { "?" } else { "" }
  field.ty.display() + suffix
}

fn emit_reserved_doc(writer : SourceWriter, numbers : Array[Int]) -> Unit {
  if numbers.length() == 0 {
    writer.line("- Reserved: none")
  } else {
    let mut text = ""
    let mut i = 0
    while i < numbers.length() {
      if i > 0 {
        text = text + ", "
      }
      text = text + numbers[i].to_string()
      i = i + 1
    }
    writer.line("- Reserved: " + text)
  }
}

fn emit_message_doc(writer : SourceWriter, msg : @schema.MessageDecl) -> Unit {
  writer.line("## Message `" + msg.name + "`")
  writer.blank()
  emit_reserved_doc(writer, msg.reserved_numbers)
  writer.blank()
  writer.line("| No. | Name | Type | Deprecated |")
  writer.line("| --- | --- | --- | --- |")
  for field in msg.fields {
    writer.line(
      "| " + field.number.to_string() +
      " | `" + field.name +
      "` | `" + field_type_display(field) +
      "` | " + yes_no(field.deprecated) + " |",
    )
  }
  writer.blank()
}

fn emit_enum_doc(writer : SourceWriter, en : @schema.EnumDecl) -> Unit {
  writer.line("## Enum `" + en.name + "`")
  writer.blank()
  emit_reserved_doc(writer, en.reserved_numbers)
  writer.blank()
  writer.line("| No. | Name |")
  writer.line("| --- | --- |")
  for item in en.cases {
    writer.line("| " + item.number.to_string() + " | `" + item.name + "` |")
  }
  writer.blank()
}

pub fn decl_file_stem(decl : @schema.Decl) -> String {
  match decl {
    @schema.Message(msg) => snake_name(msg.name)
    @schema.Enum(en) => snake_name(en.name)
  }
}

pub fn emit_decl(schema : @schema.Schema, decl : @schema.Decl) -> String {
  let writer = SourceWriter::new()
  emit_header(writer)
  match decl {
    @schema.Enum(en) => emit_enum(writer, en)
    @schema.Message(msg) => {
      emit_struct(writer, msg)
      emit_message_codec(writer, schema, msg)
    }
  }
  writer.finish()
}

pub fn emit_schema(schema : @schema.Schema) -> String {
  let writer = SourceWriter::new()
  emit_header(writer)
  for decl in schema.declarations {
    match decl {
      @schema.Enum(en) => emit_enum(writer, en)
      _ => ()
    }
  }
  for decl in schema.declarations {
    match decl {
      @schema.Message(msg) => {
        emit_struct(writer, msg)
        emit_message_codec(writer, schema, msg)
      }
      _ => ()
    }
  }
  writer.finish()
}

fn emit_message_tests(writer : SourceWriter, msg : @schema.MessageDecl) -> Unit {
  let lower = snake_name(msg.name)
  writer.line("test \"moonpack " + msg.name + " default roundtrip\" {")
  writer.push_indent()
  writer.line("let value = default_" + lower + "()")
  writer.line("let bytes = encode_" + lower + "(value)")
  writer.line("match decode_" + lower + "(bytes) {")
  writer.push_indent()
  writer.line("Ok(decoded) => if !equal_" + lower + "(value, decoded) { fail(\"roundtrip value mismatch\") }")
  writer.line("Err(_) => fail(\"roundtrip failed\")")
  writer.pop_indent()
  writer.line("}")
  writer.pop_indent()
  writer.line("}")
  writer.blank()
  writer.line("test \"moonpack " + msg.name + " sample roundtrip\" {")
  writer.push_indent()
  writer.line("let value = sample_" + lower + "()")
  writer.line("let bytes = encode_" + lower + "(value)")
  writer.line("match decode_" + lower + "(bytes) {")
  writer.push_indent()
  writer.line("Ok(decoded) => if !equal_" + lower + "(value, decoded) { fail(\"sample roundtrip value mismatch\") }")
  writer.line("Err(_) => fail(\"sample roundtrip failed\")")
  writer.pop_indent()
  writer.line("}")
  writer.pop_indent()
  writer.line("}")
  writer.blank()
}

pub fn emit_decl_tests(_schema : @schema.Schema, decl : @schema.Decl) -> String {
  match decl {
    @schema.Enum(_) => return ""
    _ => ()
  }
  let writer = SourceWriter::new()
  writer.line("// Generated by MoonPack. Do not edit by hand.")
  writer.blank()
  match decl {
    @schema.Message(msg) => emit_message_tests(writer, msg)
    _ => ()
  }
  writer.finish()
}

pub fn emit_schema_tests(schema : @schema.Schema) -> String {
  let writer = SourceWriter::new()
  writer.line("// Generated by MoonPack. Do not edit by hand.")
  writer.blank()
  for decl in schema.declarations {
    match decl {
      @schema.Message(msg) => emit_message_tests(writer, msg)
      _ => ()
    }
  }
  writer.finish()
}

pub fn emit_schema_doc(schema : @schema.Schema) -> String {
  let writer = SourceWriter::new()
  writer.line("# MoonPack Schema: `" + schema.package_name + "`")
  writer.blank()
  writer.line("Generated by `moonpack doc`.")
  writer.blank()
  writer.line("## Package")
  writer.blank()
  writer.line("`" + schema.package_name + "`")
  writer.blank()
  for decl in schema.declarations {
    match decl {
      @schema.Message(msg) => emit_message_doc(writer, msg)
      @schema.Enum(en) => emit_enum_doc(writer, en)
    }
  }
  writer.finish()
}
