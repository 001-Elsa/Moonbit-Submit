# MoonPack 参赛计划与当前状态

## 项目方向

MoonPack 是一个 MoonBit-native 的 schema-first 二进制序列化工具包。它参考 protobuf 的字段编号和 wire type 思路，但不追求 protoc 兼容，而是提供更小、更容易审阅和扩展的 MoonBit 原生实现。

目标场景：

- 游戏存档、确定性模拟快照。
- CLI 和构建工具缓存。
- 本地配置、项目元数据。
- 小型服务或工具之间的结构化数据交换。

## 已完成

- `src/core`：varint、field key、reader/writer、length-delimited、fixed64、unknown field skip。
- `src/schema`：lexer、parser、AST、validator、`reserved` 单点和范围、跨版本兼容性检查。
- `src/codegen`：生成 struct/enum、default/sample、`equal_*`、encode/decode、字段级 round-trip 测试。
- `src/cli`：
  - `check <schema.mpack>`
  - `compat <old.mpack> <new.mpack>`
  - `gen <schema.mpack> -o <dir>`
- `gen` 现在按 package 生成目录，并按声明拆成一 message/enum 一文件。
- 示例：
  - `examples/auth/auth.mpack`
  - `examples/savegame/savegame.mpack`
  - `examples/compat/savegame_v1.mpack`
  - `examples/compat/savegame_v2.mpack`
  - `examples/compat/savegame_bad.mpack`
- 文档：
  - `README.md`
  - `docs/schema-format.md`
  - `docs/wire-format.md`
  - `docs/implementation-status.md`

## 当前验证结果

在 `D:\moonbit` 运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1
```

结果：

```text
moon 0.1.20260608
moonc v0.10.0+e66899a54
Total tests: 14, passed: 14, failed: 0.
ok: demo.auth
ok: demo.savegame
ok: compatible
generated: generated/demo/savegame
Total tests: 14, passed: 14, failed: 0.
error: examples/invalid/reserved.mpack:5:3: field number 1 is reserved in message User
error: compat failed: message Save removed field 2 without reserving it
```

## 生成效果

`examples/savegame/savegame.mpack` 会生成：

```text
generated/demo/savegame/
  moon.pkg
  vec2.mbt
  vec2_test.mbt
  inventory_item.mbt
  inventory_item_test.mbt
  save_game.mbt
  save_game_test.mbt
```

关键 API：

```text
default_save_game()
sample_save_game()
equal_save_game(lhs, rhs)
encode_save_game(value)
decode_save_game(bytes)
```

## 后续可选增强

- 增加 deprecated 字段语法和更细的兼容策略。
- 增加 schema 文档生成。
- 增加 JSON bridge。
- 增加 benchmark 和更完整的比赛演示材料。
