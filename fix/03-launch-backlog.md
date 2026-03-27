# 03 Launch Backlog

更新时间：2026-03-27

本次 backlog 分三条线：

- Track A：Claude Code 自动化基础建设
- Track B：发布阻塞修复
- Track C：Codex 治理与发布材料

## Track A：Claude 自动化基础

| 任务ID | 任务 | Owner | 优先级 | 状态 | 输出物 |
|---|---|---|---|---|---|
| OP-A1 | 统一任务主键，fix 文档与执行任务板对齐 | Codex reviewer | P0 | 待开始 | 新任务板与工作流文档 |
| OP-A2 | 停用 shell supervisor 的“模拟 pass”路径 | Claude team-lead | P0 | 待开始 | 失效路径说明 / 替代方案 |
| OP-A3 | 建立 Claude team 完成门禁 | Claude team-lead | P0 | 待开始 | 任务完成规则 / hook 策略 |
| OP-A4 | 为 Claude team 固化文件 ownership 和依赖关系 | Claude team-lead | P0 | 待开始 | `07-agent-team-taskboard.md` 落地 |

## Track B：发布阻塞修复

| 任务ID | 任务 | 对应问题 | Owner | 优先级 | 状态 |
|---|---|---|---|---|---|
| LB-B1 | 安装脚本去破坏性改造 | CT-001 | Claude implementer-c | P0 | 待开始 |
| LB-B2 | 移除自动 `audit fix --force` | CT-002 | Claude implementer-c | P0 | 待开始 |
| LB-B3 | 禁止执行型配置加载 | CT-003 | Claude implementer-a | P0 | 待开始 |
| LB-B4 | `updateAppConfig` 全量参数化 | CT-004 | Claude implementer-b | P0 | 待开始 |
| LB-B5 | API Key 前置校验与错误处理 | CT-005 | Claude implementer-a | P0 | 待开始 |
| LB-B6 | TUI 输入监听治理 | CT-006 | Claude implementer-b | P1 | 待开始 |
| LB-B7 | 最小测试基线（unit + smoke） | CT-007 | Claude implementer-b | P1 | 待开始 |
| LB-B8 | lint 门禁与 CI 对齐 | CT-008 | Claude implementer-c | P1 | 待开始 |
| LB-B9 | 安装页版本选择交互优化 | CT-010 | Claude implementer-c | P1 | 待开始 |

## Track C：Codex 治理与发布材料

| 任务ID | 任务 | Owner | 优先级 | 状态 | 输出物 |
|---|---|---|---|---|---|
| GOV-C1 | 文档状态对齐与持续回写 | Codex reviewer | P0 | 进行中 | 发布治理包 |
| GOV-C2 | 每日定时检查机制 | Codex reviewer | P0 | 待开始 | 检查节奏与模板 |
| GOV-C3 | 里程碑审查结论模板 | Codex reviewer | P0 | 待开始 | 审查模板 |
| GOV-C4 | Go/No-Go 审核包准备 | Codex reviewer | P0 | 待开始 | 发布证据清单 |
| GOV-C5 | D+1 / D+3 / D+7 复盘模板 | Codex reviewer | P1 | 待开始 | 复盘文档 |

## 建议里程碑

1. M1（D+1）
- 完成 OP-A1 ~ OP-A4

2. M2（D+3）
- 完成 LB-B1 ~ LB-B5

3. M3（D+4）
- 完成 LB-B6 ~ LB-B9
- 输出首轮验证结果

4. M4（D+5）
- 完成 GOV-C2 ~ GOV-C5
- 冻结发布分支

5. M5（D+6）
- Go/No-Go 评审

## 出口条件

- Track A 完成
- 全部 P0 修复完成并通过验证
- Codex 给出可审计的独立结论
