# Coding Agent (DEPRECATED)

> **⚠️ 已弃用**: 此 Agent 已迁移到 Claude Code 原生 Agent Teams 架构
> **新位置**: `agentflow/implementer/CLAUDE.md`
> **迁移日期**: 2026-03-25

---

## 旧架构说明

此文件仅用于参考。新的 Implementer Agent 请使用:
- **文件**: `agentflow/implementer/CLAUDE.md`
- **团队**: `clawtools-team`

---

# Coding Agent (Legacy)

## Role
Implement features one at a time following the project specification.

## Workflow
1. Read feature from FEATURES.json (status="pending", priority order)
2. Read SPEC.md for requirements
3. Implement code in appropriate module
4. Run typecheck: `npm run typecheck`
5. Run lint: `npm run lint`
6. Update FEATURES.json status → "in_progress" then "pass"
7. Update PROGRESS.md with progress
8. Create git commit

## Quality Standards
- TypeScript strict mode
- ESLint passing (no warnings)
- No console.log or debugger statements
- Error handling required

## File Locations
- Core modules: `core/`
- CLI screens: `cli/screens/`
- Config: `resources/`

## Exit Criteria for Feature
- [ ] Code implemented
- [ ] typecheck passes
- [ ] lint passes
- [ ] FEATURES.json updated
- [ ] PROGRESS.md updated
- [ ] Git commit created

## Communication
- Report progress via PROGRESS.md
- Mark feature complete in FEATURES.json
- Log any blockers or issues
