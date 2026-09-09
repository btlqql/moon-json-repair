# Moon JSON Repair 申报书草稿

> AI 辅助草稿：提交前必须由申报人 btlqql 本人逐项核实、改写并确认，不得以本文件冒充本人撰写，也不得把计划功能写成已完成。

- 项目名称：Moon JSON Repair
- GitHub 地址：https://github.com/btlqql/moon-json-repair
- 模块：btlqql/moon_json_repair

## 简介

Moon JSON Repair 是一个纯 MoonBit 的保守 JSON 语法修复库：合法输入保留原文与数字拼写；每次修复记录原始 UTF-16 位置和原因；无法可靠判断时明确拒绝，不猜测缺失值。附带 Node.js 命令行与 JSONL 逐行诊断。

## 方向与通用性

面向需要把“近似 JSON”安全地转成合法 JSON 的工具链与后端预处理环节，而不是做通用 JSON5 解析器或业务 Schema 校验器。提供可复用库 API、可回放的编辑记录、严格/宽松选项与批量 JSONL 接口。

## 预期使用场景

1. AI 结构化输出预处理：LLM 返回带裸键、单引号、注释或尾逗号的 JSON 时，先生成合法 JSON 和修改记录，再由调用方做 Schema 校验与权限检查。
2. 人工配置文件纠错：对配置草稿中的裸键、尾逗号和注释做词法级修复，保留其余原文，避免重排式格式化导致 diff 混乱。
3. JSONL 日志逐行检查：逐行输入日志，输出每行成功/失败、行号、错误码与行内偏移，供数据管道定位坏行而不中断整批处理。

## 核心功能

保守修复裸键/单引号/注释/尾逗号；可选补全容器闭合；拒绝缺值、缺冒号、重复键、多根值、未结束字符串等不可靠输入；编辑记录可回放并校验；严格模式禁用修复；提供 Node CLI 与 JSONL 报告。

## 技术路线

纯 MoonBit 递归下降解析器 + 编辑日志；字符串/数字合法性委托 MoonBit core JSON 能力；无第三方依赖。测试覆盖固定回归、生成式不变量与 CLI 集成，CI 覆盖 wasm/wasm-gc/js/native 四后端。

## 预计交付成果与不做范围

交付可复现源码、README、示例、核心路径测试、CI、MoonCakes 包。首版不做：JSON5 全兼容、缺失中间值猜测、Markdown 围栏剥离、JSONP/Python 字面量、多根合并、网络下载或自动覆盖源文件。

## 原创/移植/参考来源与许可证

原创 MoonBit 实现；功能边界参考 josdejong/jsonrepair（ISC）但未复制其源码或测试；已核对 MoonCakes/GitHub 中 MBOpenClacky 内部 helper 与 MoonParse 等相邻项，说明差异而非声称“无同类”。许可证 Apache-2.0。

## 真实需求、生态差异、本人理解

实际工具链常收到“近似 JSON”而非严格 JSON；通用解析器要么拒绝，要么做不可审计的全局替换。本项目的差异点是可回放编辑记录与显式拒绝边界。申报人需在此补充本人对适用边界的理解及为什么不做缺失值猜测。

## 提交前核对

GitHub 公开访问、≥10 个真实有效提交、作者归属、CI 通过、MoonCakes 版本可获取；报名问卷与赛事群加入以当天官方口径为准。
