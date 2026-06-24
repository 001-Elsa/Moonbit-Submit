fn print_usage() -> Unit {
  println("MoonPack")
  println("")
  println("Usage:")
  println("  moonpack check <schema.mpack>")
  println("  moonpack compat <old.mpack> <new.mpack>")
  println("  moonpack gen <schema.mpack> -o <dir>")
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

fn command_gen(path : String, out_dir : String) -> Unit {
  let schema = read_schema(path)
  let package_dir = package_output_dir(out_dir, schema.package_name)
  for decl in schema.declarations {
    let stem = @codegen.decl_file_stem(decl)
    let output = package_dir + "/" + stem + ".mbt"
    @fs.write_string_to_file(output, @codegen.emit_decl(schema, decl)) catch {
      _ => fail("cannot write generated file '\{output}'")
    }
    let tests = @codegen.emit_decl_tests(schema, decl)
    if tests.length() > 0 {
      let test_output = package_dir + "/" + stem + "_test.mbt"
      @fs.write_string_to_file(test_output, tests) catch {
        _ => fail("cannot write generated test file '\{test_output}'")
      }
    }
  }
  let pkg = "import {\n  \"local/moonpack/src/core\" @core\n}\n"
  @fs.write_string_to_file(package_dir + "/moon.pkg", pkg) catch {
    _ => fail("cannot write generated package file")
  }
  println("generated: " + package_dir)
}

fn main {
  let args = @sys.get_cli_args()
  if args.length() < 2 {
    print_usage()
    @sys.exit(1)
  }
  match args[1] {
    "check" => {
      if args.length() != 3 {
        print_usage()
        @sys.exit(1)
      }
      command_check(args[2])
    }
    "compat" => {
      if args.length() != 4 {
        print_usage()
        @sys.exit(1)
      }
      command_compat(args[2], args[3])
    }
    "gen" => {
      if args.length() != 5 || args[3] != "-o" {
        print_usage()
        @sys.exit(1)
      }
      command_gen(args[2], args[4])
    }
    _ => {
      print_usage()
      @sys.exit(1)
    }
  }
}
