# MoonPack 专业完善计划

## 项目当前状态

MoonPack 当前已经是一个可运行的 MoonBit-native schema-first 二进制序列化 MVP。项目已经具备 schema 解析、校验、代码生成、CLI、示例和基础文档，定位清晰：参考 protobuf 的字段编号与 wire type 思路，但不追求 protoc 兼容，而是提供更小、更容易审阅和扩展的 MoonBit 原生方案。

当前已完成能力：

- `src/core`：varint、field key、reader/writer、length-delimited、fixed64、unknown field skip。
- `src/schema`：lexer、parser、AST、validator、`reserved` 单点和范围校验、跨版本兼容性检查。
- `src/codegen`：生成 struct/enum、`default_*`、`sample_*`、`equal_*`、`encode_*`、`decode_*` 和 round-trip 测试。
- `src/cli`：支持 `check`、`compat`、`gen` 三个核心命令。
- `examples`：包含 auth、savegame、compat、invalid 等示例。
- `docs` 与 `README.md`：已经说明 schema 格式、wire format、当前实现状态和比赛价值。

当前验证基线：

```powershell
moon check
moon test
powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1
```

预期基线结果：

```text
Total tests: 17, passed: 17, failed: 0.
ok: demo.auth
ok: demo.savegame
ok: compatible
generated: generated/demo/savegame (7 files)
documented: docs/generated/demo/savegame.md
```

## 比赛冲刺目标

比赛阶段的目标不是把 MoonPack 做成大型通用协议栈，而是把 MVP 打磨成“完整、可信、好展示”的 MoonBit 生态工具项目。优先级按评分影响排序：

1. 稳定性：保证 `check` / `compat` / `gen` / generated tests 全流程稳定通过。
2. 完整度：补齐 schema 演进、文档生成、JSON bridge、benchmark 等能体现工程价值的能力。
3. 展示力：让评委能快速看懂 MoonPack 解决的问题、使用方式、技术亮点和边界。
4. MoonBit 原生性：突出 parser、validator、wire format、codegen 都由 MoonBit 实现。
5. 小而清晰：继续避免追求 protobuf 全兼容，保持项目范围可控。

比赛提交建议使用 `Moonbit-Submit-main` 作为提交包参考，但后续开发和计划维护以根目录 `D:\moonbit` 为主项目。

## 第一阶段：评分提升优先项

第一阶段以比赛效果为中心，建议按下面顺序推进。

### 1. 完善 schema 演进能力

新增 `deprecated` 字段语法和兼容性规则，优先采用字段级标记，示例形态如下：

```text
message SaveGame {
  1: player_id String
  2: old_score Int deprecated
  3: level Int
}
```

实现目标：

- AST 中为字段增加 `deprecated : Bool`。
- parser 能识别字段末尾 `deprecated` 标记。
- validator 禁止新增字段复用 deprecated 或 reserved 的语义冲突。
- compat 检查允许“先 deprecated，后 reserved，再删除”的演进路径。
- docs 中补充字段废弃策略，说明它与 `reserved` 的区别。

验收标准：

- deprecated 字段仍可正常生成 encode/decode。
- 删除旧字段但未 reserved 时仍然报错。
- 删除旧字段并 reserved 后兼容性检查通过。
- `moon test` 覆盖 deprecated 正反用例。

### 2. 增加 JSON bridge 演示亮点

JSON bridge 的目标是展示 MoonPack 不只是二进制编码，也能服务调试、工具链和数据迁移。第一阶段可以先做演示级能力，不必追求完整 JSON 标准库封装。

建议路线：

- 在 codegen 中为生成类型增加 `to_json_*` 和 `from_json_*` 规划接口，先支持示例 schema。
- 或新增独立 demo，将 `sample_save_game()` 转换成 JSON-like 文本，再从文本恢复。
- README 中加入“binary round-trip + JSON debug view”的演示片段。

验收标准：

- savegame 示例能展示结构化 JSON 文本。
- JSON bridge 有 round-trip 测试。
- 错误输入能给出可读错误，而不是静默生成错误对象。

### 3. 增加 schema 文档生成

新增 `moonpack doc <schema.mpack> -o <dir>` 作为比赛展示命令，生成 Markdown 文档，展示 package、message、field、enum、reserved、deprecated 信息。

计划接口：

```text
moonpack doc examples/savegame/savegame.mpack -o docs/generated
```

生成结果建议：

```text
docs/generated/demo/savegame.md
```

文档内容包括：

- package 名称。
- message 列表和字段表格。
- enum 列表和 tag 表格。
- reserved / deprecated 说明。
- wire type 简要提示。

验收标准：

- `doc` 命令对 auth 和 savegame 示例都能生成 Markdown。
- 生成文档不依赖外部 Node 工具。
- 文档内容与 schema 一致。

### 4. 增强 CLI 可用性

当前 CLI 已有核心命令，下一步重点是让用户和评委“试一次就懂”。

建议增强：

- 支持 `moonpack --help` 和 `moonpack <command> --help`。
- `gen` 输出生成文件数量和目标目录。
- 错误信息保持 `path:line:column`，并补充错误原因。
- `gen` 可选支持 `--no-tests`，用于只生成运行时代码。
- `gen` 可选支持 `--clean`，用于清理旧生成文件后再生成。

验收标准：

- 参数错误时输出 usage 并返回非 0。
- schema 错误能定位到文件、行、列。
- 生成成功信息包含目标目录和文件数量。

### 5. 补充 benchmark 与比赛演示材料

benchmark 不需要和成熟协议库硬比性能，重点是证明 MoonPack 的编码结果紧凑、测试可重复、场景真实。

建议新增：

- `examples/benchmark/savegame_large.mpack` 或生成大量 savegame 数据的测试。
- `scripts/bench.ps1`，输出编码次数、字节数、耗时。
- README 中增加 Benchmark 小节。
- 比赛展示材料中补充一张流程图：`.mpack -> AST -> validate -> codegen -> encode/decode/tests`。

验收标准：

- benchmark 脚本可重复运行。
- 输出包含 schema 名称、样本数量、总字节数、耗时。
- 结果用于展示趋势，不承诺跨机器绝对性能。

## 第二阶段：产品化增强路线

第二阶段面向真实用户和长期维护，优先提升稳定性、可扩展性和生态接入。

### 1. Schema 语言扩展

建议逐步加入：

- package import：允许 schema 引用其他 `.mpack` 文件。
- 注释保留：文档生成能读取字段和 message 注释。
- 字段默认值：例如 `3: level Int = 1`。
- map 类型：例如 `Map[String, Int]`，但需要先明确 wire format。
- oneof / union：适合协议消息，但会扩大 AST、validator 和 codegen 复杂度，应放到后期。

默认取舍：

- 优先做注释保留和默认值。
- 暂缓 map 和 oneof，避免比赛阶段引入不稳定 wire 设计。

### 2. 代码生成可配置化

后续可支持：

- 生成目录策略配置。
- 是否生成测试文件。
- 是否生成 JSON helper。
- 是否按 message 拆文件。
- 生成 API 前缀或命名风格配置。

建议命令形态：

```text
moonpack gen schema.mpack -o generated --with-json --no-tests
```

保持现有默认行为不变，避免破坏已有示例。

### 3. 错误模型与诊断系统

当前错误已经能给出基本位置。产品化阶段建议统一错误模型：

- parse error、validation error、compat error、decode error 分层。
- 每类错误有稳定 code，例如 `MP_PARSE_001`。
- CLI 输出人类可读文本，库接口保留结构化错误。
- 文档列出常见错误和修复建议。

### 4. 发布与生态集成

长期目标：

- 准备 MoonBit 包发布说明。
- 增加版本策略：`0.1.x` 保持 MVP 兼容，`0.2.x` 引入 schema 扩展。
- 增加 changelog。
- 提供最小项目模板：`examples/minimal-app`。
- 增加 CI 脚本，至少运行 `moon check`、`moon test`、CLI smoke test。

## 技术实施清单

建议按下面顺序执行，避免同时改动太多模块。

### Milestone A：比赛稳定版

- 运行并记录当前基线：`moon check`、`moon test`、`scripts/check.ps1`。
- 修正已有文档中的路径或编码问题，保证中文文档使用 UTF-8。
- README 增加一段“快速验收命令”。
- 确认提交包不包含 `.moonhome`、`.toolchains`、`node_modules` 等不必要目录。

### Milestone B：deprecated 兼容性

- 修改 AST、lexer/parser、validator、compat。
- 增加 schema 测试：deprecated parse、删除未 reserved、删除并 reserved。
- 更新 `docs/schema-format.md` 和 README。
- 运行完整检查脚本。

### Milestone C：文档生成

- 新增 doc emitter，复用 schema AST。
- CLI 增加 `doc` 命令。
- 为 auth/savegame 生成 Markdown 示例。
- 增加 smoke test，验证生成文件存在且包含关键字段。

### Milestone D：JSON bridge 与 benchmark

- 先为 savegame 示例实现 JSON debug view。
- 增加 round-trip 测试。
- 新增 benchmark 脚本和 README 结果说明。
- 准备比赛展示截图或输出片段。

## 验证与验收标准

基础验收每次必须通过：

```powershell
moon check
moon test
powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1
```

比赛冲刺验收：

- 示例 schema 能完成 `check -> gen -> moon check -> moon test`。
- 兼容性失败场景能给出明确错误。
- `README.md`、`docs/*`、申报材料与实际能力一致。
- 提交包体积合理，不包含工具链缓存和依赖缓存。

产品化验收：

- 新增 CLI 命令均有正向和反向测试。
- JSON bridge 有 round-trip 测试。
- benchmark 有可重复运行脚本和结果说明。
- 生成代码 API 保持向后兼容，默认行为不破坏当前示例。

## 风险与取舍

- 不追求 protobuf 兼容：这是项目定位，不是缺陷。MoonPack 应强调 MoonBit-native、小而可审阅、比赛可完成。
- 暂缓复杂类型：`Map`、`oneof`、跨文件 import 会明显增加复杂度，应放到第二阶段。
- JSON bridge 先做演示闭环：第一阶段以 savegame 示例和调试视图为主，避免过早承诺完整 JSON Schema 能力。
- benchmark 谨慎表述：用于说明趋势和可重复性，不做跨机器绝对性能承诺。
- 文档优先级高：比赛场景中，清晰 README、示例和申报材料对评分很关键。

## 推荐下一步

最推荐的下一步是先完成 Milestone A 和 Milestone B：

1. 固定当前可运行基线。
2. 修正文档编码和提交包内容。
3. 实现字段级 `deprecated`。
4. 扩展兼容性测试。
5. 更新 README 和 schema 文档。

完成后，MoonPack 会从“可运行 MVP”提升为“具备 schema 演进能力的 MoonBit 原生序列化工具”，这对比赛展示和长期产品化都是最划算的一步。
