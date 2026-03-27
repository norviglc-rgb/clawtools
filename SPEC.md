# ClawTools 需求说明书（执行版）

更新时间：2026-03-27
版本：0.2.0

## 1. 文档定位

本文件描述 ClawTools 的当前产品范围、发布目标与执行边界。

旧版 `FEAT-*` 状态体系已彻底废弃，不再作为任务调度依据。
当前执行以 `fix/` 目录为准。

## 2. 目标与范围

### 目标

- 让用户稳定完成安装、配置、诊断和首次可用主流程
- 以安全、稳定、可回滚为发布底线
- 采用双轨模式：
  - Claude Code 负责自动化开发执行
  - Codex 负责审查、文档治理和发布复核

### In Scope

- P0/P1 阻塞修复
- 最小测试基线与 lint 门禁
- 发布 runbook、验证矩阵、监控阈值、回滚预案

### Out of Scope

- 大规模 UI 重构
- 与首发链路无关的长期重构

## 3. 当前执行模型

权威文档优先级：

1. `fix/01-go-no-go-criteria.md`
2. `fix/07-agent-team-taskboard.md`
3. `fix/08-agent-workflows.md`
4. `fix/04-validation-matrix.md`

执行角色：

- Claude team-lead：拆解、分配、门禁、升级阻塞
- Claude implementer-a：CT-003、CT-005
- Claude implementer-b：CT-004、CT-006、CT-007
- Claude implementer-c：CT-001、CT-002、CT-008、CT-010
- Codex reviewer：日检、里程碑审查、Go/No-Go 复核、复盘

## 4. 修复工作项（发布窗口）

| Work Item | 对应问题 | 优先级 | Owner | 目标结果 |
|---|---|---|---|---|
| WI-01 | CT-001 | P0 | implementer-c | 安装脚本无破坏性默认行为 |
| WI-02 | CT-002 | P0 | implementer-c | 默认安装不自动 `audit fix --force` |
| WI-03 | CT-003 | P0 | implementer-a | 配置加载不执行任意 JS |
| WI-04 | CT-004 | P0 | implementer-b | `updateAppConfig` 全参数化 |
| WI-05 | CT-005 | P0 | implementer-a | API Key 前置校验完整 |
| WI-06 | CT-006 | P1 | implementer-b | TUI 输入监听稳定 |
| WI-07 | CT-007 | P1 | implementer-b | 最小测试基线可执行 |
| WI-08 | CT-008 | P1 | implementer-c | lint 门禁真实生效 |
| WI-09 | CT-010 | P1 | implementer-c | 安装交互符合预期 |

## 5. 验收标准

### 任务级验收

任务进入 `done` 前必须提供：

- 修改文件
- 验证命令
- 验证结果
- 风险说明
- 回滚点

### 发布级验收

必须满足 `fix/01-go-no-go-criteria.md` 的全部 Must 项。

## 6. 技术与平台

### 技术栈

- Node.js
- TypeScript
- Ink（TUI）
- SQLite

### 平台优先级

- Windows PowerShell：主路径（Must）
- Linux Bash：兼容路径
- macOS Bash/Zsh：兼容路径

## 7. 质量门禁

- `npm run typecheck` 通过
- `npm run lint` 为真实检查并通过
- `npm run test` 可执行且最小集通过
- `fix/04-validation-matrix.md` Must Cases 全通过

## 8. 发布与回滚

发布流程、灰度策略、回滚触发与外部沟通统一参照：

- `fix/05-release-runbook.md`
- `fix/06-post-launch-metrics.md`

## 9. 设计原则

- 安全优先
- 主流程优先
- 证据优先于口头状态
- 自动化必须有人工监督兜底
