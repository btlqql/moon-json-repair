# Moon JSON Repair — 项目申报书（技术校订稿）

> AI 辅助校订的准备材料，尚未完成本人撰写要求，不可直接提交。请本人独立组织最终一页 Markdown，并补充末节；删除提示不等于完成本人撰写。

**项目与仓库：** Moon JSON Repair，https://github.com/btlqql/moon-json-repair 。
**方向与简介：** 数据处理基础库，以 MoonBit 实现有限 JSON 语法修复。输出合法 JSON 和原始 UTF-16 编辑记录，允许回放核对；合法输入保留原文，无法可靠判断时拒绝。面向需要预览、追踪文本改动的工具，不绑定业务 Schema。

## 三个预期场景

1. AI 输出带裸键或单引号 → repair 返回文本及修改记录 → 调用方核对修改并做 Schema/权限校验；缺值或重复键时拒绝并重试，不猜测业务数据。
2. 配置草稿含注释、尾逗号 → CLI --report 预览原始位置与替换内容 → 人工确认后另存；不覆盖原文件，不能可靠修复时交回作者处理。
3. JSONL 批量导入 → repair_jsonl 返回逐行状态、错误码与偏移 → 管道保留成功行并隔离失败行，不丢弃错误报告。

## 核心、路线与范围

已实现裸键/单引号/注释/尾逗号修复、可选容器闭合、编辑回放、严格策略和 JSONL/Node CLI。使用递归下降、原文切片和编辑列表；限制输入、深度及编辑数。重复键错误为 `Rejected("DUPLICATE_KEY", offset)`。

不做完整 JSON5、缺值猜测、自然语言意图判断或业务安全保证；不自动覆盖文件。容器闭合默认关闭，因为截断输入可能已改变数值含义。

## 来源与生态差异

独立 MoonBit 实现，Apache-2.0；功能边界参考 [jsonrepair](https://github.com/josdejong/jsonrepair)（ISC），未导入源码/测试。现有 [tiye/json5](https://github.com/worktools/json5.mbt)（Apache-2.0）已经覆盖主要宽松语法，必须承认重叠；本项目不以这些语法支持为新增价值。

拟说明的区别是原始位置编辑日志、回放校验和未修改文本保留，而非更广的语法覆盖。详见仓库 [对比与可运行证据](https://github.com/btlqql/moon-json-repair/blob/main/docs/json5-comparison.md)、[来源说明](https://github.com/btlqql/moon-json-repair/blob/main/docs/provenance.md)。这些区别是否达到赛事要求仍需评审判断。

## 交付与验证

源码、README、示例、测试、四后端 CI 和许可证已具备。[MoonCakes 0.1.0](https://mooncakes.io/docs/btlqql/moon_json_repair@0.1.0) 已发布并完成独立安装验证。本次仓库补充 3 个契约测试（合计 19 个）、审计示例和统一验证入口；这些新增材料未包含在已发布的 0.1.0 包内，属于后续源码更新。

复现：`node scripts/verify.mjs --target js`（目标可换 wasm、wasm-gc、native）。本次四后端本地测试通过，native 使用临时 C11 编译适配且有运行时警告；另完成 CLI、打包后复测及独立边界检查。远端结果见[对应提交的 CI](https://github.com/btlqql/moon-json-repair/actions/workflows/ci.yml)。官方失败仍待日志定位，[复现记录](https://github.com/btlqql/moon-json-repair/blob/main/docs/reproduction.md)明确环境与限制，不承诺必过审。

## 本人填写：实际需求与方案理解

【请本人写明真实使用者/遇到的问题、为什么现有 JSON5 解析不能满足该需求、亲自完成的工作，以及如何验证编辑记录有用。没有实际使用记录时请明确是预期场景，不编造用户或效果。】
