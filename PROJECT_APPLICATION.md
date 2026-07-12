# MoonPack Project Application

## Basic Information

| Field | Value |
| --- | --- |
| Project name | MoonPack: MoonBit-native schema-first binary serialization toolkit |
| Participant | 韩桢 |
| Email | 766903826@qq.com |
| Phone | 17889572851 |
| GitHub repository | https://github.com/001-Elsa/Moonbit-Submit |
| Gitlink repository | https://gitlink.org.cn/Hanzzz/MoonPack_Hz |
| Mooncakes package | `001-Elsa/moonpack@0.1.1` |
| Project direction | MoonBit infrastructure / developer tooling / data serialization |
| Project type | Original project |

## Project Summary

MoonPack is a schema-first binary serialization toolkit for the MoonBit
ecosystem. It provides a compact `.mpack` schema language, schema parsing and
validation, compatibility checks, MoonBit code generation, CLI tooling,
generated Markdown documentation, examples, and reproducible generated test
fixtures.

The project targets a reusable infrastructure gap in MoonBit: simple,
inspectable, MoonBit-native data exchange for tools, game saves, local
configuration, caches, small services, and test fixtures.

## Core Features

- `.mpack` schema language with `message`, `enum`, `List[T]`, optional `T?`,
  `reserved`, and `deprecated`.
- Schema toolchain with lexer, parser, validator, and compatibility checker.
- Compact tag-based binary wire format with varint, fixed64,
  length-delimited values, and unknown-field skipping.
- MoonBit code generation for structs, enums, default values, sample values,
  equality helpers, encode/decode functions, and round-trip tests.
- CLI commands: `check`, `compat`, `gen`, and `doc`.
- Example schemas and generated MoonBit/demo documentation.

## Originality Statement

MoonPack is an original project. It references the field-number and wire-type
idea used by Google Protocol Buffers, but the schema language, MoonBit code
generation, compatibility rules, CLI, tests, and implementation are designed
for MoonBit and are not protoc-compatible.

Reference project:

- Protocol Buffers: https://github.com/protocolbuffers/protobuf
- Reference license: BSD 3-Clause License

## Delivery And Verification Evidence

- Local full acceptance script passed:
  `powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1 -Update`
- Local tests passed: 43 tests passed.
- GitHub Actions verified CI passed:
  https://github.com/001-Elsa/Moonbit-Submit/actions/runs/29194651605
- GitHub and Gitlink are synchronized to the final submission contents.
- Published Mooncakes package: `001-Elsa/moonpack@0.1.1`
- Package fetch command: `moon fetch 001-Elsa/moonpack@0.1.1`
- Root `LICENSE` is Apache-2.0.

## Submission Links

- GitHub: https://github.com/001-Elsa/Moonbit-Submit
- Gitlink: https://gitlink.org.cn/Hanzzz/MoonPack_Hz
- CI: https://github.com/001-Elsa/Moonbit-Submit/actions/runs/29194651605
- Mooncakes: `001-Elsa/moonpack@0.1.1`
