# AgentFlow - Claude Code 主开发架构

更新时间：2026-03-27

本目录服务于 Claude Code 的主开发团队，不负责 Codex 的监督逻辑。

## 当前架构

```text
clawtools-team
├── team-lead
├── implementer-a
├── implementer-b
└── implementer-c
```

Codex 是 team 外部监督者，不在本架构内。

## 架构原则

- 主任务来源是 `fix/07-agent-team-taskboard.md`
- 主执行流程是 `fix/08-agent-workflows.md`
- Claude team 负责实现与自检
- Codex 负责审查、纠偏、文档回写、Go/No-Go

## 为什么停用旧方案

以下旧方案已不再有效：

- 旧 FEAT-* 任务编号驱动分配
- shell supervisor 自动推进
- 用脚本直接把任务写成 `pass`

原因：

- 会制造假完成
- 与当前 fix 文档任务体系不一致
- 无法满足 “完成必须带证据” 的治理要求

## 有效执行模型

### team-lead

- 只做分配、协调、阻塞升级、完成包检查
- 不主动吞实现任务

### implementers

- 各自拥有固定文件域
- 按 work item 执行
- 完成后提交完成包

## 启动要求

创建 Claude team 时，必须明确以下提示：

- 目标仅限修复 P0/P1 发布阻塞
- 任务来源是 `fix/07-agent-team-taskboard.md`
- 不允许无验证直接完成
- 避免同文件并发修改
- 如 agent teams 不稳定，暂停并等待人工介入

## 推荐团队规模

- `1` 个 lead
- `3` 个 implementer

这是当前仓库最稳妥的并发规模。除非任务板发生明显扩容，不建议继续增加 teammate 数量。

## 关键文件

- `agentflow/TEAM.md`
- `agentflow/team-lead/CLAUDE.md`
- `agentflow/implementer/CLAUDE.md`
- `fix/07-agent-team-taskboard.md`
- `fix/08-agent-workflows.md`
- `fix/04-validation-matrix.md`
