# Implementation Status

MoonPack is implemented as a MoonBit module in this repository.

## Done

- Project plan in `plan.md`.
- Moon module metadata in `moon.mod`.
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

Use a standard MoonBit toolchain with `moon` available on `PATH`. The helper
scripts also support a local `.moonhome` directory under the project root or its
parent directory.

## Verified

Run from the repository root:

```powershell
moon check
moon build
moon test
```

Current result:

- `moon check`: passed.
- `moon build`: passed.
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
- Field-level `deprecated` markers for schema evolution.
- Markdown schema documentation through `moonpack doc <schema.mpack> -o <dir>`.

## Next Implementation Pass

1. Add JSON bridge helpers for generated demo types.
2. Add richer generated API customization options.
3. Add benchmark scripts and more contest presentation assets.
