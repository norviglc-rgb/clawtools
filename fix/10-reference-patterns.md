# 10 Reference Patterns

更新时间：2026-03-27

本文件记录本次重构直接参考的外部模式，以及它们如何影响 ClawTools 的执行设计。

## 1. Claude Code Agent Teams 官方文档

参考：

- https://code.claude.com/docs/en/agent-teams

提炼出的关键结论：

- Agent teams 适合“可并行、边界清晰、需要互相协调”的任务
- 不适合大量同文件修改和强顺序依赖任务
- team lead 容易抢实现，必须显式要求其“等待队员完成”
- 任务应拆成清晰 deliverable，并限制 3-5 个 teammate 起步
- 实验特性存在 session resumption、任务状态滞后、清理不彻底等限制

因此在本项目中的应用：

- Claude 用 1 个 lead + 3 个 implementer
- 每个 implementer 只拥有固定文件域
- Codex 不加入 team，避免把监督层耦进实验性执行层

## 2. Claude 开发 + Codex 审查的 review-loop 模式

参考：

- https://github.com/hamelsmu/claude-review-loop/blob/main/README.md

提炼出的关键结论：

- Claude 做主实现，Codex 做独立 second opinion，是一种可复用治理模式
- 审查最好发生在任务完成后、用户接受前，而不是事后补写总结
- 多个 Codex review 视角并行可以提升问题发现率

因此在本项目中的应用：

- Codex 不负责主实现，只做 review、文档、复盘
- Claude 任务从 `in_progress` 进入 `review_ready` 后，等待 Codex 或等价审查
- Go/No-Go 必须有 Codex 独立结论

## 3. OpenClaw 官方安装文档

参考：

- https://github.com/openclaw/openclaw/blob/main/docs/start/getting-started.md
- https://openclawlab.com/en/docs/install/

提炼出的关键结论：

- 官方推荐安装入口仍是一键脚本
- Windows 路径要特别关注，且 WSL2 往往更稳定
- 安装后必须有清晰的验证命令，如 `doctor`、`status`、`dashboard`
- 文档应把“最快可用路径”和“备用安装路径”分开

因此在本项目中的应用：

- ClawTools 必须将安装、配置、诊断作为同一主路径治理
- Windows 是首要验证对象
- Runbook 中必须强调“失败原因可见”

## 4. OpenClaw Windows 安装故障案例

参考：

- https://github.com/openclaw/openclaw/issues/38054
- https://github.com/openclaw/openclaw/issues/41797
- https://github.com/openclaw/openclaw/pull/38634

提炼出的关键结论：

- Windows 安装的一大风险不是单纯失败，而是“失败后窗口立刻关闭，用户无法看到原因”
- PowerShell 中 `exit 1`、`Out-Null`、未检查 `$LASTEXITCODE`、管道污染都可能制造假成功或黑盒失败
- 安装脚本修复不能只修 happy path，必须覆盖错误可见性和宿主 shell 不被杀死

因此在本项目中的应用：

- CT-001 和安装链路治理不仅看“能不能装”，还看“失败时用户看不看得到原因”
- Validation Matrix 新增对错误可见性与假完成风险的检查
- Codex 审查必须检查是否存在“看似成功、实则失败”的路径

## 5. 本次设计的落地原则

- 外部参考只用来定义方向，不直接复制流程
- 任何自动化完成判定都必须落到仓库证据
- 任何实验性 agent 能力都必须配套人工审查兜底
