///|
pub struct Schema {
  package_name : String
  declarations : Array[Decl]
}

///|
pub enum Decl {
  Message(MessageDecl)
  Enum(EnumDecl)
}

///|
pub struct MessageDecl {
  name : String
  fields : Array[FieldDecl]
  reserved_numbers : Array[Int]
}

///|
pub struct FieldDecl {
  number : Int
  name : String
  ty : TypeRef
  optional : Bool
  deprecated : Bool
  line : Int
  column : Int
}

///|
pub struct EnumDecl {
  name : String
  cases : Array[EnumCase]
  reserved_numbers : Array[Int]
}

///|
pub struct EnumCase {
  number : Int
  name : String
  line : Int
  column : Int
}

///|
pub enum TypeRef {
  BoolType
  IntType
  Int64Type
  DoubleType
  StringType
  BytesType
  NamedType(String)
  ListType(TypeRef)
}

///|
pub fn TypeRef::display(self : TypeRef) -> String {
  match self {
    BoolType => "Bool"
    IntType => "Int"
    Int64Type => "Int64"
    DoubleType => "Double"
    StringType => "String"
    BytesType => "Bytes"
    NamedType(name) => name
    ListType(inner) => "List[" + inner.display() + "]"
  }
}
