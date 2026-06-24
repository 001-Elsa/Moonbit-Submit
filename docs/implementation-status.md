# Implementation Status

Created in `D:\moonbit`.

## Done

- Project plan in `plan.md`.
- Moon module metadata in `moon.mod.json`.
- Package layout under `src/`.
- Core wire-format files:
  - `src/core/error.mbt`
  - `src/core/bytes.mbt`
  - `src/core/reader.mbt`
  - `src/core/writer.mbt`
  - `src/core/varint.mbt`
  - `src/core/wire.mbt`
- Schema frontend:
  - `src/schema/ast.mbt`
  - `src/schema/token.mbt`
  - `src/schema/lexer.mbt`
  - `src/schema/parser.mbt`
  - `src/schema/validate.mbt`
- Code generation skeleton:
  - `src/codegen/names.mbt`
  - `src/codegen/moonbit_writer.mbt`
  - `src/codegen/emit.mbt`
- CLI entry skeleton:
  - `src/cli/main.mbt`
- Generated sample package:
  - `generated/demo/savegame/moon.pkg`
  - one generated `.mbt` file per message/enum
  - generated round-trip tests per message
- Examples:
  - `examples/auth/auth.mpack`
  - `examples/savegame/savegame.mpack`
- Documentation:
  - `README.md`
  - `docs/wire-format.md`
  - `docs/schema-format.md`

## Toolchain

MoonBit was installed under `D:\moonbit\.moonhome` with `MOON_HOME` set to that
directory. The official installer script was downloaded to
`D:\moonbit\.downloads\moonbit-install.ps1` and run with both `HOME` and
`MOON_HOME` redirected under `D:\moonbit`.

The project also contains the earlier downloaded zip under `D:\moonbit\.downloads`
and extracted binaries under `D:\moonbit\.toolchains`.

## Verified

Run from `D:\moonbit`:

```powershell
$env:PATH='D:\moonbit\.moonhome\bin;' + $env:PATH
$env:MOON_HOME='D:\moonbit\.moonhome'
moon check
moon test
```

Current result:

- `moon check`: passed.
- `moon test`: passed with package tests and generated default round-trip tests.

CLI checks:

```powershell
moon run src/cli -- check examples/auth/auth.mpack
moon run src/cli -- check examples/savegame/savegame.mpack
moon run src/cli -- gen examples/savegame/savegame.mpack -o generated
moon run src/cli -- check examples/invalid/reserved.mpack
```

Current generated-code coverage:

- Bool, Int, Int64, Double, String, Bytes.
- Optional fields.
- Repeated fields via `List[T]`.
- Enums with int mapping helpers.
- Nested messages.
- Unknown field skipping.
- Reserved field/tag number checks with path, line, and column CLI errors.
- Stable snake_case generated API names.

## Next Implementation Pass

1. Broaden compatibility rules for explicit deprecated fields.
2. Add richer generated API customization options.
3. Add more demos and screenshots for contest presentation.
