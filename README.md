# Moon JSON Repair

[![CI](https://github.com/btlqql/moon-json-repair/actions/workflows/ci.yml/badge.svg)](https://github.com/btlqql/moon-json-repair/actions/workflows/ci.yml)

纯 MoonBit JSON 格式修复库：保留合法输入的原文，对每一次修复记录位置和原因；
不能可靠处理时明确拒绝，不伪造缺失的业务数据。命令行仅使用少量 Node.js IO 适配代码。

## 功能与边界

| 输入问题 | 默认行为 |
| --- | --- |
| ASCII 裸键、单引号字符串 | 按词法规则补引号/转换引号 |
| 行注释、块注释、尾逗号 | 删除并记录原始位置；不修改字符串里的相同字符 |
| 完整值之后缺少容器闭括号 | 默认拒绝；显式 `--close-containers` 才补全 |
| 缺值、缺冒号、缺中间逗号、未结束字符串 | 拒绝，不猜测 |
| 重复键（包括转义后相同的键） | 拒绝，避免悄悄覆盖数据 |
| Python 常量、JSONP、Markdown 围栏、多个根值 | 不支持 |

合法 JSON 保留空白、数字原始拼写和大整数，不经 Double 重新序列化。
这不是完整 JSON5 或上游 jsonrepair 的兼容实现，也不是 JSON Schema 验证器。
严格模式还会拒绝重复键，因此比部分 JSON 解析器更严格。

## 运行

开发验证版本：MoonBit `0.1.20260904`，Node.js 24。

```sh
git clone https://github.com/btlqql/moon-json-repair.git
cd moon-json-repair
moon run examples/basic --target js
moon run cmd/main --target js -- --report examples/config.txt
moon run cmd/main --target js -- --jsonl examples/events.jsonl
```

最后一个示例故意包含一条错误记录，退出码为 1。可先构建后直接运行：

```sh
moon build --target js
node _build/js/debug/build/cmd/main/main.js --help
node _build/js/debug/build/cmd/main/main.js --report examples/config.txt
```

不指定路径或指定 `-` 时读取 UTF-8 标准输入。只输出到 stdout/stderr，**不覆盖原文件**。
`--strict` 禁用修复；`--close-containers` 显式允许容器补全；`--report` 输出修改记录。
JSONL 模式始终输出每行报告，失败行不会被删除。退出码：0 全部成功，1 拒绝/部分失败，2 参数或 IO 错误。

## 作为库使用

模块名为 `btlqql/moon_json_repair`。发布状态请以 MoonCakes 页面为准；
发布成功后安装命令为 `moon add btlqql/moon_json_repair@0.1.0`。
接口与契约见 [README.mbt.md](README.mbt.md)。

## 验证

```sh
moon fmt --check
moon check --target all --deny-warn
moon build --target all --deny-warn
moon test --target all --deny-warn
moon run examples/basic --target js
node scripts/test-cli.mjs
moon package --list
```

native 后端需要现代 C 编译器。库覆盖 wasm、wasm-gc、js、native；CLI 仅支持 JS/Node。
测试包含 3000 个确定性生成输入、100 个成功修复组合、Unicode/边界/拒绝案例及 13 项 CLI 集成检查。
数量是测试输入数量，不代表独立的人工测试用例，也不代表已经覆盖所有 JSON 异常。

## 工程与来源

- [设计和安全边界](docs/design.md)
- [查重与参考来源](docs/provenance.md)
- [申报前技术事实核对表](docs/applicant-notes.md)（不是代写申报书）
- [申报书草稿](docs/proposal-draft.md)（AI 辅助草稿，须本人改写确认）
- [版本记录](CHANGELOG.md)

代码、测试和文档由维护者使用 AI 编程辅助工具开发；参赛者需亲自理解、验证并撰写申报书。
本仓库不含 Moon Tera 的代码或提交历史。许可证：[Apache-2.0](LICENSE)。

