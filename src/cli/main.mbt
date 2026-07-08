fn print_usage() -> Unit {
  println("MoonPack")
  println("")
  println("Usage:")
  println("  moonpack check <schema.mpack>")
  println("  moonpack compat <old.mpack> <new.mpack>")
  println("  moonpack gen <schema.mpack> -o <dir> [--no-tests]")
  println("  moonpack doc <schema.mpack> -o <dir>")
}

fn[T] fail(message : String) -> T {
  println("error: " + message)
  @sys.exit(1)
  abort(message)
}

fn parse_and_validate(path : String, text : String) -> @schema.Schema {
  match @schema.parse_schema(text) {
    Err(err) => fail(path + ":" + @schema.parse_error_to_string(err))
    Ok(schema) => match @schema.validate_schema(schema) {
      Err(err) => fail(path + ":" + @schema.parse_error_to_string(err))
      Ok(_) => schema
    }
  }
}

fn read_schema(path : String) -> @schema.Schema {
  let text = @fs.read_file_to_string(path) catch {
    _ => fail("cannot read schema file '\{path}'")
  }
  parse_and_validate(path, text)
}

fn ensure_dir(path : String) -> Unit {
  if !@fs.path_exists(path) {
    @fs.create_dir(path) catch {
      _ => fail("cannot create output directory '\{path}'")
    }
  }
}

fn package_parts(package_name : String) -> Array[String] {
  let parts : Array[String] = []
  let mut start = 0
  let mut i = 0
  while i < package_name.length() {
    if package_name[i].to_int() == 46 {
      parts.push(package_name[start:i].to_owned())
      start = i + 1
    }
    i = i + 1
  }
  parts.push(package_name[start:package_name.length()].to_owned())
  parts
}

fn package_output_dir(out_dir : String, package_name : String) -> String {
  ensure_dir(out_dir)
  let parts = package_parts(package_name)
  let mut current = out_dir
  for part in parts {
    current = current + "/" + part
    ensure_dir(current)
  }
  current
}

fn package_doc_path(out_dir : String, package_name : String) -> String {
  ensure_dir(out_dir)
  let parts = package_parts(package_name)
  let mut current = out_dir
  let mut i = 0
  while i + 1 < parts.length() {
    current = current + "/" + parts[i]
    ensure_dir(current)
    i = i + 1
  }
  current + "/" + parts[parts.length() - 1] + ".md"
}

fn command_check(path : String) -> Unit {
  let schema = read_schema(path)
  println("ok: " + schema.package_name)
}

fn command_compat(old_path : String, new_path : String) -> Unit {
  let old_schema = read_schema(old_path)
  let new_schema = read_schema(new_path)
  match @schema.check_compatible(old_schema, new_schema) {
    Ok(_) => println("ok: compatible")
    Err(err) => fail("compat failed: " + err)
  }
}

fn command_gen(path : String, out_dir : String, write_tests : Bool) -> Unit {
  let schema = read_schema(path)
  let package_dir = package_output_dir(out_dir, schema.package_name)
  let mut count = 0
  for decl in schema.declarations {
    let stem = @codegen.decl_file_stem(decl)
    let output = package_dir + "/" + stem + ".mbt"
    @fs.write_string_to_file(output, @codegen.emit_decl(schema, decl)) catch {
      _ => fail("cannot write generated file '\{output}'")
    }
    count = count + 1
    let tests = @codegen.emit_decl_tests(schema, decl)
    if write_tests && tests.length() > 0 {
      let test_output = package_dir + "/" + stem + "_test.mbt"
      @fs.write_string_to_file(test_output, tests) catch {
        _ => fail("cannot write generated test file '\{test_output}'")
      }
      count = count + 1
    }
  }
  let pkg = "import {\n  \"local/moonpack/src/core\" @core\n}\n"
  @fs.write_string_to_file(package_dir + "/moon.pkg", pkg) catch {
    _ => fail("cannot write generated package file")
  }
  count = count + 1
  println("generated: " + package_dir + " (" + count.to_string() + " files)")
}

fn command_doc(path : String, out_dir : String) -> Unit {
  let schema = read_schema(path)
  let output = package_doc_path(out_dir, schema.package_name)
  @fs.write_string_to_file(output, @codegen.emit_schema_doc(schema)) catch {
    _ => fail("cannot write schema documentation '\{output}'")
  }
  println("documented: " + output)
}

fn main {
  let args = @sys.get_cli_args()
  if args.length() < 2 || args[1] == "--help" || args[1] == "-h" {
    print_usage()
    if args.length() < 2 {
      @sys.exit(1)
    }
    @sys.exit(0)
  }
  match args[1] {
    "check" => {
      if args.length() == 3 && (args[2] == "--help" || args[2] == "-h") {
        print_usage()
        @sys.exit(0)
      }
      if args.length() != 3 {
        print_usage()
        @sys.exit(1)
      }
      command_check(args[2])
    }
    "compat" => {
      if args.length() == 3 && (args[2] == "--help" || args[2] == "-h") {
        print_usage()
        @sys.exit(0)
      }
      if args.length() != 4 {
        print_usage()
        @sys.exit(1)
      }
      command_compat(args[2], args[3])
    }
    "gen" => {
      if args.length() == 3 && (args[2] == "--help" || args[2] == "-h") {
        print_usage()
        @sys.exit(0)
      }
      if (args.length() != 5 && args.length() != 6) || args[3] != "-o" {
        print_usage()
        @sys.exit(1)
      }
      let write_tests = if args.length() == 6 {
        if args[5] == "--no-tests" {
          false
        } else {
          print_usage()
          @sys.exit(1)
          true
        }
      } else {
        true
      }
      command_gen(args[2], args[4], write_tests)
    }
    "doc" => {
      if args.length() == 3 && (args[2] == "--help" || args[2] == "-h") {
        print_usage()
        @sys.exit(0)
      }
      if args.length() != 5 || args[3] != "-o" {
        print_usage()
        @sys.exit(1)
      }
      command_doc(args[2], args[4])
    }
    _ => {
      print_usage()
      @sys.exit(1)
    }
  }
}
