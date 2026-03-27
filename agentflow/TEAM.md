# ClawTools Team - Claude Code 主开发团队说明

更新时间：2026-03-27

本文件定义 Claude Code agent team 的唯一有效组织方式。Codex 不属于该 team，而是在 team 外部做监督、审查和文档治理。

## 团队信息

| 属性 | 值 |
|------|-----|
| Team Name | `clawtools-team` |
| Team Lead | `team-lead` |
| 工作目录 | `d:\AI\ClawTools\clawtools` |
| 主任务来源 | `fix/07-agent-team-taskboard.md` |
| 主流程来源 | `fix/08-agent-workflows.md` |

## 角色

### `team-lead`

职责：

- 读取 `fix/07-agent-team-taskboard.md`
- 按依赖拆解任务并分配给 implementer
- 控制 WIP、避免文件冲突
- 检查完成包是否满足 Definition of Done
- 遇到阻塞时升级，不亲自抢实现任务

### `implementer-a`

职责：

- 安全与配置链路实现

范围：

- CT-003
- CT-005

建议文件域：

- `core/configurator.ts`
- `cli/screens/config.tsx`

### `implementer-b`

职责：

- 数据层、稳定性、测试

范围：

- CT-004
- CT-006
- CT-007

建议文件域：

- `db/index.ts`
- `cli/App.tsx`
- `tests/*`

### `implementer-c`

职责：

- 安装、发布链路、lint、交互优化

范围：

- CT-001
- CT-002
- CT-008
- CT-010

建议文件域：

- `scripts/install.ps1`
- `package.json`
- `cli/screens/install.tsx`
- `.github/workflows/*` 中与 lint/release 相关部分

## 不属于 Claude Team 的角色

### Codex Reviewer

Codex 不是 team member，不领取实现任务，不直接推动 Claude 的任务状态。

Codex 负责：

- 日检
- 阶段审查
- 发布 readiness 审查
- fix 文档与验证矩阵回写
- 复盘

## 状态机

允许状态：

- `pending`
- `in_progress`
- `blocked`
- `review_ready`
- `done`

禁止状态：

- 无证据 `done`
- 用脚本直接写 `pass`

## 任务完成要求

每个任务进入 `review_ready` 之前，必须附上完成包：

- 修改文件
- 验证命令
- 验证结果
- 风险说明
- 回滚点

## 调度原则

- 每个 implementer 同时最多 1 个 `in_progress`
- 同文件不允许并发修改
- P0 任务失败 2 次必须升级
- 阻塞超过 4 小时必须升级
- team-lead 优先等待 implementer 完成，不自行吞掉任务

## 质量门禁

在任务标记 `review_ready` 前至少完成：

- `npm run typecheck`
- 与任务相关的 `lint/test/smoke`
- 无 console.log/debugger
- 风险说明已写明

## 已废弃内容

以下内容不再作为有效执行依据：

- 旧 FEAT 编号分配方式
- shell supervisor 自动推进
- “同步 agent 自动回写完成状态”

如果这些机制与 fix 文档冲突，以 `fix/` 下最新治理文档为准。
