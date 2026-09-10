# Moon JSON Repair — 人工申报准备清单

> AI 辅助技术资料，不是可提交的项目申报书。请参赛者独立撰写一页 Markdown；
> 不能删掉这句提示后将本文件作为本人撰写材料提交。无需 PDF。

- 名称 / 仓库：[Moon JSON Repair](https://github.com/btlqql/moon-json-repair)。
- 方向 / 需求：通用数据预处理库，处理可可靠识别的 JSON 词法错误，保留原文与修改证据。
- 核心：裸键、单引号、注释、尾逗号修复；可选容器闭合；UTF-16 编辑记录回放；JSONL 与 Node CLI。
- 路线：MoonBit 递归下降解析、编辑日志、MoonBit core 词法验证；固定/生成式测试及四目标 CI。
- 不做：缺值猜测、完整 JSON5、业务 Schema 校验、自动覆盖源文件。合法语法不等于业务安全。

## 场景事实（请本人结合实际使用者写完整）

1. LLM 输出带裸键的对象 → 调用 repair 得到合法 JSON 和编辑记录 → 下游再做 Schema/权限检查；缺失业务值时拒绝并要求上游重试。
2. 配置草稿含注释/尾逗号 → CLI 预览修改报告 → 人工确认后另存；不覆盖源文件，无法可靠修复时返回错误码。
3. JSONL 日志夹杂坏行 → 按行诊断 → 返回行号、状态与偏移；保留失败报告供数据管道隔离处理。

## 来源、差异与交付核对

独立 MoonBit 实现，Apache-2.0。[jsonrepair](https://github.com/josdejong/jsonrepair)
（ISC）为功能参考，未导入源码/测试。已有内部修复 helper 和 JSON5 解析器，
本项目差异是独立可复用 API、可回放编辑记录与明确拒绝边界，不声称“没有同类”。
详细链接见 [来源说明](provenance.md)。

已具备源码、README、示例、测试、CI、许可证；MoonCakes 发布仍需单独确认。
请本人补充选题动机、适用边界理解、真实开发工作和交付计划。
提交前按 [赛事核对表](submission-checklist.md) 核验账号、有效提交、发布和人工材料。
