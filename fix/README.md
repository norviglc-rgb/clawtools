# ClawTools 发布治理包（Claude Code 主开发 / Codex 主监督）

更新时间：2026-03-27

本目录现已重构为一套可执行的发布治理包，核心原则如下：

- Claude Code 是主开发引擎：负责自动化 agent teams 规划、实现、联调、自检、回写状态。
- Codex 是外部监督层：负责文档维护、阶段审查、偏航纠正、发布复核、复盘沉淀。
- 两者不争抢同一职责：Claude 负责“做”，Codex 负责“盯、验、记、纠偏”。

## 为什么这样设计

- 当前仓库最需要的是连续、高速、低等待的修复执行，Claude Code 更适合承担主实现工作。
- 纯自动化 agent teams 容易出现“误判完成、质量门禁被绕过、文档不同步”。
- 因此 Codex 不进入主开发回路，而是作为独立监督者，按固定节奏和关键节点复核，防止 Claude 跑偏。

## 文档阅读顺序

1. `00-release-goals.md`
2. `01-go-no-go-criteria.md`
3. `02-risk-register.md`
4. `03-launch-backlog.md`
5. `07-agent-team-taskboard.md`
6. `08-agent-workflows.md`
7. `04-validation-matrix.md`
8. `05-release-runbook.md`
9. `06-post-launch-metrics.md`
10. `09-skill-utilization-matrix.md`
11. `10-reference-patterns.md`

## 本次重构后的执行模型

### Claude Code 负责

- 自动创建并管理 agent team
- 按任务板拆解并执行 P0/P1 修复
- 本地自检：typecheck、lint、test、构建、关键 smoke
- 在每个任务完成时附上变更文件、验证命令、风险说明、回滚点
- 在 hook 或任务完成门禁中阻止“无证据完成”

### Codex 负责

- 每日定时检查和阶段性人工复核
- 安全、稳定性、文档一致性、发布 readiness 审查
- 对 Claude 输出做二次 review，指出漏测、越权修改、风险遗漏
- 维护发布包文档、验证矩阵、风险台账、复盘材料
- 在 Go/No-Go 前给出独立结论

## 当前状态

- 发布结论：`No-Go`
- 原因：主阻塞问题尚未修复，且新的自动化执行治理还未完全落地
- 可进入执行阶段的前提：
  - Claude Code agent teams 编排、任务板、门禁已对齐
  - Codex 的定时审查节奏和产出模板已固定
  - `04-validation-matrix.md` 的 Must Cases 有明确执行人与证据落点

## 历史技术附录

以下文档仍保留，作为技术证据与修复附录：

- `00-project-map.md`
- `01-issue-board.md`
- `02-fix-playbook.md`
- `03-security-audit.md`

## 本目录回答的不是“修什么”，而是“怎么让 Claude 高速做、让 Codex 稳定盯”

如果执行中出现冲突，以以下优先级为准：

1. `01-go-no-go-criteria.md`
2. `08-agent-workflows.md`
3. `07-agent-team-taskboard.md`
4. `03-launch-backlog.md`
5. 其他附录与背景文档
