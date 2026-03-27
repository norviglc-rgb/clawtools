# 07 Agent Team Taskboard

更新时间：2026-03-27

本文件定义 Claude Code 的主开发编排。Codex 不加入该 team，而是在 team 之外做监督。

## 1. 组织模型

### Claude Code Team

- `team-lead`
  - 负责任务拆解、依赖管理、WIP 控制、完成门禁

- `implementer-a`
  - 负责安全与配置链路
  - 范围：CT-003、CT-005

- `implementer-b`
  - 负责数据层、稳定性、测试
  - 范围：CT-004、CT-006、CT-007

- `implementer-c`
  - 负责安装、发布链路、lint
  - 范围：CT-001、CT-002、CT-008、CT-010

### Codex 外部角色

- `codex-reviewer`
  - 不领取 Claude 任务
  - 只做检查、审查、文档回写、升级阻塞

## 2. 任务状态机

允许状态：

- `pending`
- `in_progress`
- `blocked`
- `review_ready`
- `done`

不允许状态：

- `pass` 但无验证证据
- `done` 但无回滚点

## 3. 完成定义（Definition of Done）

任一任务标记 `done` 前必须包含：

1. 变更文件列表
2. 验证命令与结果
3. 风险说明
4. 回滚点
5. 如涉及 UI/交互，附 smoke 结果
6. 如涉及安全/数据，附测试或审查证据

## 4. 任务板

| Work Item | 任务 | Owner | 依赖 | 文件范围 | 完成条件 |
|---|---|---|---|---|---|
| WI-01 | 安装脚本去破坏性改造 | implementer-c | 无 | `scripts/install.ps1` | 无危险默认命令，失败信息可读 |
| WI-02 | 移除默认 `audit fix --force` | implementer-c | 无 | `package.json`, `scripts/install.ps1` | 默认安装不再强修依赖 |
| WI-03 | 禁止执行型配置加载 | implementer-a | 无 | `core/configurator.ts` | 不再执行 `config.js` |
| WI-04 | 参数化 `app_config` 更新 | implementer-b | 无 | `db/index.ts` | 无 SQL 拼接输入 |
| WI-05 | API Key 前置校验 | implementer-a | WI-03 | `cli/screens/config.tsx`, `core/configurator.ts` | 缺密钥阻断，正常路径可保存 |
| WI-06 | TUI 输入监听治理 | implementer-b | 无 | `cli/App.tsx`, `cli/screens/*` | 不再 `removeAllListeners('data')` |
| WI-07 | 最小测试基线 | implementer-b | WI-03/04/05/06 | `tests/*`, 脚本/配置 | `npm run test` 可执行 |
| WI-08 | lint 门禁落地 | implementer-c | 无 | `package.json`, lint 配置, CI | `npm run lint` 真正生效 |
| WI-09 | 安装交互优化 | implementer-c | WI-01/02 | `cli/screens/install.tsx` | 当前选中项与回车一致 |

## 5. 调度规则

- 每个 implementer 同时最多 1 个 `in_progress`
- 任何任务阻塞超过 4 小时必须升级
- 任何 P0 任务连续失败 2 次必须暂停并升级
- team-lead 自己不抢实现任务，优先等待队员完成

## 6. 文件 ownership 约束

- implementer-a
  - `core/configurator.ts`
  - `cli/screens/config.tsx`

- implementer-b
  - `db/index.ts`
  - `cli/App.tsx`
  - `tests/*`

- implementer-c
  - `scripts/install.ps1`
  - `package.json`
  - `cli/screens/install.tsx`
  - `.github/workflows/*` 中与 lint/release 相关部分

若必须跨 ownership 修改，必须先由 team-lead 重新分配。

## 7. Claude Team Lead 提示要求

创建团队时必须明确说明：

- 目标是修复 P0/P1 发布阻塞，不做额外扩展
- 先研究，再拆任务，再执行
- 完成任务前必须附验证结果
- 不要自己把未验证任务标记完成
- 避免同文件并发修改
- 如果发现 agent teams 不稳定，暂停并等待 Codex 介入
