# MoonPack Schema Format

MoonPack schema files use the `.mpack` extension.

## Package

Every schema starts with a package declaration.

```text
package demo.auth
```

## Message

Messages contain numbered fields.

```text
message User {
  reserved 9
  1: id Int64
  2: name String
}
```

Field numbers are part of the wire format and must not be reused for a
different meaning after release.

## Enum

```text
enum UserStatus {
  reserved 3
  0: Unknown
  1: Active
}
```

## Reserved Numbers

Use `reserved <number>` or `reserved <start>..<end>` inside a `message` or
`enum` to prevent a field number or enum tag from being reused.

```text
message User {
  reserved 4
  reserved 10..20
  1: id Int64
}
```

If a later field reuses a reserved number, MoonPack reports a path, line, and
column in the CLI.

## Types

Built-in types:

- `Bool`
- `Int`
- `Int64`
- `Double`
- `String`
- `Bytes`

Compound types:

- `List[T]`
- `T?`
- named message or enum references

## Comments

Line comments start with `//`.
