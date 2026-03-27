# 01 Go-No-Go Criteria

更新时间：2026-03-27

## 决策规则

- 任一 `Must` 未通过 -> `No-Go`
- 全部 `Must` 通过，且 `Should` 达标 >= 80% -> `Go`
- 若 Claude Code 自动化链路异常且无法切到受控人工模式 -> `No-Go`

## Must（上线硬门槛）

### A. 代码与安全

1. CT-001 已修复
- 安装脚本不再包含破坏性默认行为

2. CT-003 已修复
- 运行时不再执行型加载配置

3. CT-004 已修复
- 配置更新 SQL 全参数化

4. CT-005 已修复
- API Key 加密链路具备前置校验和明确失败提示

### B. 自动化执行链路

5. Claude Code agent teams 已可运行
- 已启用团队模式
- team-lead / implementer 分工明确
- 任务来源以 `07-agent-team-taskboard.md` 为准

6. 任务完成门禁真实生效
- 任务未附验证结果不可标记完成
- 不允许 shell supervisor 模拟标记 `pass`

7. Codex 外部监督链路可运行
- 存在固定日检节奏
- 存在阶段性审查模板
- 能独立输出阻塞结论

### C. 质量与验证

8. `npm run typecheck` 通过
9. `npm run lint` 为真实检查且通过
10. `npm run test` 可执行且 Must 测试通过
11. `04-validation-matrix.md` 中 Must Cases 全通过
12. Windows 主路径安装 / 配置 / 诊断 smoke 通过

### D. 发布与回滚

13. `05-release-runbook.md` 已补齐并完成演练
14. 回滚演练至少 1 次并有记录
15. 发布证据包已齐全
- 验证结果
- 风险台账
- 已知问题
- 豁免项
- Codex 审查结论

## Should（建议门槛）

- CT-010 交互优化完成
- CT-009 文档一致性问题完成主要修正
- Linux / macOS 兼容路径完成最小验证
- 已接入发布后 D+1 / D+3 / D+7 复盘模板
- Codex 日检结果连续 2 次无新增高风险偏航

## 明确禁止作为 Go 依据的情况

- 仅凭 Claude 自报“已完成”
- 仅凭 typecheck 通过
- 仅凭手工口头确认
- 验证矩阵仍为 `待测`
- shell 脚本自动把任务状态写成 `pass`

## 角色签署

- 产品负责人（PM）：确认目标、用户影响、范围边界
- 项目经理（PgM）：确认节奏、依赖、风险、资源
- Claude Code Team Lead：确认自动执行状态、任务收敛情况
- Codex Reviewer：确认审查结论、残留风险、文档真实性
- 测试负责人（QA，如有人类角色参与）：确认验证报告

签署结论：`Go / No-Go`
签署日期：`____-__-__`
