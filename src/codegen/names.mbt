pub fn upper_first(name : String) -> String {
  if name.length() == 0 {
    name
  } else {
    name[0:1].to_owned().to_upper() + name[1:name.length()].to_owned()
  }
}

pub fn lower_first(name : String) -> String {
  if name.length() == 0 {
    name
  } else {
    name[0:1].to_owned().to_lower() + name[1:name.length()].to_owned()
  }
}

fn is_upper_code(code : Int) -> Bool {
  code >= 65 && code <= 90
}

fn lower_code_unit(code : Int) -> String {
  if is_upper_code(code) {
    String::from_array([Int::unsafe_to_char(code + 32)])
  } else {
    String::from_array([Int::unsafe_to_char(code)])
  }
}

pub fn snake_name(name : String) -> String {
  let mut out = ""
  let mut i = 0
  while i < name.length() {
    let code = name[i].to_int()
    if i > 0 && is_upper_code(code) {
      out = out + "_"
    }
    out = out + lower_code_unit(code)
    i = i + 1
  }
  out
}

pub fn package_to_path(package_name : String) -> String {
  let mut out = ""
  for ch in package_name {
    if ch == '.' {
      out = out + "/"
    } else {
      out = out + ch.to_string()
    }
  }
  out
}

pub fn moonbit_type_name(ty : @schema.TypeRef, optional : Bool) -> String {
  let base = match ty {
    @schema.BoolType => "Bool"
    @schema.IntType => "Int"
    @schema.Int64Type => "Int64"
    @schema.DoubleType => "Double"
    @schema.StringType => "String"
    @schema.BytesType => "Array[Byte]"
    @schema.NamedType(name) => name
    @schema.ListType(inner) => "Array[" + moonbit_type_name(inner, false) + "]"
  }
  if optional {
    base + "?"
  } else {
    base
  }
}
