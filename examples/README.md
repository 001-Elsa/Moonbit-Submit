# Examples

This directory contains small schemas used to demonstrate and verify MoonPack.

## `auth/auth.mpack`

Shows a compact account-oriented schema with:

- scalar fields
- optional fields
- repeated string fields through `List[String]`
- enum values

Run:

```powershell
moon run src/cli -- check examples/auth/auth.mpack
```

## `savegame/savegame.mpack`

Shows nested messages, repeated message fields, optional values, reserved field
numbers, reserved ranges, and deprecated fields. This schema is used for the
generated demo package under `generated/demo/savegame`.

Run:

```powershell
moon run src/cli -- check examples/savegame/savegame.mpack
moon run src/cli -- gen examples/savegame/savegame.mpack -o generated
moon run src/cli -- doc examples/savegame/savegame.mpack -o docs/generated
```

## `world/world.mpack`

Shows a larger game-world schema with multiple enums, nested messages, repeated
message fields, optional nested messages, reserved ranges, and a deprecated
debug field. This fixture is intended to exercise code generation at a larger
scale than the minimal savegame example.

Run:

```powershell
moon run src/cli -- check examples/world/world.mpack
moon run src/cli -- gen examples/world/world.mpack -o generated
moon run src/cli -- doc examples/world/world.mpack -o docs/generated
```

## `compat/`

Contains schema evolution fixtures:

- `savegame_v1.mpack`: old schema version.
- `savegame_v2.mpack`: compatible schema version.
- `savegame_bad.mpack`: intentionally incompatible schema used by tests.

Run:

```powershell
moon run src/cli -- compat examples/compat/savegame_v1.mpack examples/compat/savegame_v2.mpack
```

## `invalid/reserved.mpack`

Contains an intentionally invalid schema where a field reuses a reserved number.
The CLI should report a path, line, and column in the diagnostic.
