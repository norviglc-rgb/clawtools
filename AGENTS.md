# ClawTools Agent Operating Model

更新时间：2026-03-27

本仓库只保留一套有效 agent 体系：

- Claude Code：主开发执行（agent team）
- Codex：外部监督、审查、文档与复盘

## 权威文档

按以下顺序执行：

1. `fix/01-go-no-go-criteria.md`
2. `fix/07-agent-team-taskboard.md`
3. `fix/08-agent-workflows.md`
4. `fix/04-validation-matrix.md`

## Claude Code 角色

- `team-lead`：任务拆解、分配、门禁检查、阻塞升级
- `implementer-a`：CT-003、CT-005
- `implementer-b`：CT-004、CT-006、CT-007
- `implementer-c`：CT-001、CT-002、CT-008、CT-010

详细说明见：

- `agentflow/TEAM.md`
- `agentflow/team-lead/CLAUDE.md`
- `agentflow/implementer/CLAUDE.md`

## Codex 角色

Codex 不加入 Claude team，不领取实现任务。

Codex 负责：

- 定时检查
- 里程碑审查
- 发布 readiness 结论
- 文档回写与复盘沉淀

## 强制规则

- 旧 supervisor/sync 体系已彻底废弃
- 不允许脚本自动写“完成”
- 不允许无验证证据关闭任务
- 任务完成必须附：修改文件、验证命令与结果、风险说明、回滚点
