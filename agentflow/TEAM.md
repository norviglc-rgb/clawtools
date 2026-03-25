# ClawTools Team - 团队架构文档

## 团队信息

| 属性 | 值 |
|------|-----|
| **Team Name** | clawtools-team |
| **Description** | ClawTools OpenClaw 管理套件开发团队 |
| **Team Lead** | team-lead |
| **工作目录** | d:\AI\ClawTools\clawtools |

## Agent 成员

### team-lead

**角色**: 团队主管
**映射自**: 旧架构 Supervisor Agent
**职责**:
- 从 FEATURES.json 分配任务给 implementer
- 跟踪进度，更新 Task list
- 判断退出条件
- 遇到模糊问题时联网搜索

**通信**:
- 分配任务: `SendMessage(to: "implementer-{a|b|c}")`
- 接收报告: `SendMessage(from: implementer-*)`
- 联网搜索: `WebSearch`, `WebFetch`

---

### implementer-a

**角色**: 功能实现者
**映射自**: 旧架构 Coding Agent
**职责**:
- 实现分配的功能
- 遵循质量标准 (typecheck, lint)
- 完成后报告 team-lead

**分配任务**:
1. FEAT-001: API Key 安全存储
2. FEAT-013: 配置模板

**通信**:
- 接收任务: `SendMessage(from: team-lead)`
- 完成任务: `SendMessage(to: "team-lead")`

---

### implementer-b

**角色**: 功能实现者
**映射自**: 旧架构 Coding Agent
**职责**:
- 实现分配的功能
- 遵循质量标准

**分配任务**:
1. FEAT-006: 安全扫描
2. FEAT-012: 迁移导出 (P2)

**通信**:
- 接收任务: `SendMessage(from: team-lead)`
- 完成任务: `SendMessage(to: "team-lead")`

---

### implementer-c

**角色**: 功能实现者
**映射自**: 旧架构 Coding Agent
**职责**:
- 实现分配的功能
- 遵循质量标准

**分配任务**:
1. FEAT-009: 版本选择

**通信**:
- 接收任务: `SendMessage(from: team-lead)`
- 完成任务: `SendMessage(to: "team-lead")`

---

### sync-writer

**角色**: 同步写入
**类型**: 新增 (旧架构无直接映射)
**职责**:
- 维护 FEATURES.json 和 Task list 的同步
- 初始化时同步 pending 任务到 Task list
- 运行时将 Task 完成状态回写到 FEATURES.json

**通信**:
- 响应 team-lead 的同步请求

---

## 任务分配矩阵

| Implementer | 任务 | 依赖模块 | 优先级 |
|-------------|------|----------|--------|
| implementer-a | FEAT-001 | core/configurator.ts | P0 |
| implementer-b | FEAT-006 | (独立) | P1 |
| implementer-c | FEAT-009 | core/installer.ts | P0 |
| implementer-a | FEAT-013 | config/providers.ts | P1 |
| implementer-b | FEAT-012 | (独立) | P2 |

## 并行策略

### Phase 1 (当前)
- implementer-a → FEAT-001
- implementer-b → FEAT-006
- implementer-c → FEAT-009

### Phase 2 (后续)
- implementer-a → FEAT-013
- implementer-b → FEAT-012

## 双轨制同步

```
FEATURES.json (持久化)          Task list (运行时)
        │                              │
        │  初始化: 同步 pending         │
        │ ───────────────────────────→ │
        │                              │
        │  运行时: Task 完成回写         │
        │ ←─────────────────────────── │
        │                              │
        │  冲突时 Task list 权威        │
```

## 联网搜索配置

Team Lead 在以下情况下使用 `WebSearch`:
- TypeScript 编译错误不明确
- 依赖包版本问题
- API 行为不确定
- 技术方案选型

**搜索限制**: 每次问题最多 3 次搜索

## 质量门禁

所有 implementer 在报告完成前必须确认:
- [ ] `npm run typecheck` 通过
- [ ] `npm run lint` 通过 (无 warnings)
- [ ] 无 console.log/debugger
- [ ] FEATURES.json 已更新

## 退出条件

所有条件满足时 Team Lead 退出:
- 所有 P0/P1 features status="pass"
- Task list 无 in_progress 任务
- 无 open P0/P1 bug

## 关键文件

| 文件路径 | 用途 |
|----------|------|
| `clawtools/FEATURES.json` | 任务持久化存储 |
| `clawtools/SPEC.md` | 项目规格文档 |
| `clawtools/core/*.ts` | 核心业务逻辑 |
| `clawtools/cli/screens/*.tsx` | TUI 界面 |
| `clawtools/agentflow/team-lead/CLAUDE.md` | Team Lead 指令 |
| `clawtools/agentflow/implementer/CLAUDE.md` | Implementer 指令 |
| `clawtools/agentflow/sync/CLAUDE.md` | Sync 指令 |

## CI/CD 集成

`.github/workflows/supervisor.yml` 可配置为:
1. 触发 Team 创建
2. 分配初始任务
3. 监控进度
4. 创建 checkpoint
