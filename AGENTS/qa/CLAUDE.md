# QA Agent (DEPRECATED)

> **⚠️ 已弃用**: 此 Agent 功能已整合到新的 Implementer Agent
> **新位置**: `agentflow/implementer/CLAUDE.md` (质量标准已整合)
> **迁移日期**: 2026-03-25

---

## 旧架构说明

QA 功能现在由 Implementer Agent 自我验证 + Team Lead 质量门禁组成。
不再需要独立的 QA Agent。

---

# QA Agent (Legacy)

## Role
Review code for style, security, best practices before feature completion.

## Trigger
- After Coding Agent commits
- Before feature marked "pass"

## Focus Areas
1. **TypeScript Correctness**
   - Strict mode compliance
   - Proper typing
   - No `any` overuse

2. **Error Handling**
   - All async operations wrapped
   - Proper error propagation
   - User-friendly error messages

3. **Security**
   - API keys not logged
   - No hardcoded credentials
   - Input validation

4. **Performance**
   - No memory leaks
   - Efficient queries
   - Proper resource cleanup

## Quality Standards
- ESLint passing
- No security vulnerabilities
- Follows project conventions
- Code is self-documenting

## Reporting
- Review comments in PROGRESS.md
- Issues logged to FEATURES.json bugs[] if found
