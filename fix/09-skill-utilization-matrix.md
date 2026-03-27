# 09 Skill Utilization Matrix

更新时间：2026-03-27

本文件不再只回答“用什么 skill”，而是回答“Claude 和 Codex 分别用什么能力、在什么节点用、谁最终负责”。

## 1. Claude Code 能力矩阵

| 能力 | 用途 | 责任角色 | 使用场景 |
|---|---|---|---|
| Agent Teams | 并行实现与协调 | Claude team-lead | P0/P1 修复主流程 |
| `security-review` | 安装脚本、配置执行、密钥处理 | implementer-a / team-lead | CT-001/003/005 |
| `tdd-workflow` | 关键逻辑先测后改 | implementer-b | CT-004/005/007 |
| `coding-standards` | TypeScript 质量统一 | 全部 implementer | 所有代码改动 |
| `e2e-testing` | 主流程 smoke 验证 | implementer-b | CT-007/010 |
| `verification-loop` | 里程碑验收自检 | team-lead | 发布前 |
| WebSearch / GitHub 调研 | 解决不清晰实现问题 | team-lead | 遇到未知方案、平台差异 |

## 2. Codex 能力矩阵

| 能力 | 用途 | 责任角色 | 使用场景 |
|---|---|---|---|
| 文档重构与回写 | 维护 fix 包真实性 | codex-reviewer | 每日 / 里程碑 |
| 代码审查 | 发现风险、漏测、边界问题 | codex-reviewer | `review_ready` 任务、里程碑 |
| 发布 readiness 审查 | 给出独立 Go/No-Go 结论 | codex-reviewer | 发布前 |
| 复盘总结 | 沉淀偏航与治理经验 | codex-reviewer | D+1 / D+3 / D+7 |
| 外部研究 | 查同类安装工具、工作流实践 | codex-reviewer | 方案不清晰时 |

## 3. 推荐的职责边界

### Claude Code

- 主实现
- 自测
- 初步验证
- 风险上报

### Codex

- 次级审查
- 文档治理
- 节奏控制
- 偏航纠正
- 复盘沉淀

## 4. 不清晰问题的查资料策略

### Claude Code 查资料

适用于：

- 某个库/API 行为不确定
- 某个安装命令在平台上的边界条件不清晰
- 某个实现方案需要快速确认

### Codex 查资料

适用于：

- 要重新设计流程、制度、审查机制
- 要参考外部最佳实践
- 要核对同类产品安装体验和真实故障模式

## 5. 本项目建议强制启用的组合

- Claude team-lead：`verification-loop` + `security-review`
- Claude implementer-a：`security-review` + `coding-standards`
- Claude implementer-b：`tdd-workflow` + `e2e-testing`
- Claude implementer-c：`security-review` + `coding-standards`
- Codex reviewer：外部研究 + 代码审查 + 文档治理

## 6. 定时检查建议

Codex 至少在以下时点执行：

1. 每日开始时
2. 每日结束前
3. M1/M2/M3/M4 里程碑结束时
4. 灰度前
5. 灰度 30 分钟后
6. 全量发布前

建议固定为本地工作日 `09:30` 与 `18:30`，其余检查随里程碑和发布窗口追加。

## 7. 结论

这套方案里，skill 不是主角，职责边界才是主角：

- Claude 的 skill 服务于“更快做对”
- Codex 的能力服务于“别做偏、别误判、别带病上线”
