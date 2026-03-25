# AgentFlow v3.0 - Claude Code Agent Teams 架构

> 从 Shell 脚本迁移到 Claude Code 原生 Agent Teams

## 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                     clawtools-team                          │
├─────────────────────────────────────────────────────────────┤
│  team-lead                                                  │
│  ├── 任务分配 (SendMessage)                                 │
│  ├── 进度跟踪 (TaskList/TaskUpdate)                         │
│  ├── 联网搜索 (WebSearch/WebFetch)                          │
│  └── 退出判断                                               │
├─────────────────────────────────────────────────────────────┤
│  implementer-a  │  implementer-b  │  implementer-c          │
│  FEAT-001       │  FEAT-006       │  FEAT-009               │
│  (并行)          │  (并行)          │  (并行)                  │
├─────────────────────────────────────────────────────────────┤
│  sync-writer                                                 │
│  └── FEATURES.json ↔ Task list 双向同步                     │
└─────────────────────────────────────────────────────────────┘
```

## 与旧架构对比

| 方面 | 旧架构 (init.sh) | 新架构 (Agent Teams) |
|------|------------------|----------------------|
| 并发 | 顺序执行 | 3个 implementer 并行 |
| 任务调度 | shell 脚本 | Task list 原生 |
| 状态存储 | JSON 文件 + PID | FEATURES.json + Task |
| Agent 调用 | claude --print | SendMessage 原生 |
| 联网能力 | 无 | WebSearch/WebFetch |
| 依赖检查 | 手动 | 自动 + 任务分配时检查 |

## 核心文件

| 文件 | 用途 |
|------|------|
| `agentflow/team-lead/CLAUDE.md` | Team Lead 指令 |
| `agentflow/implementer/CLAUDE.md` | Implementer 指令 |
| `agentflow/sync/CLAUDE.md` | 同步 Agent 指令 |
| `agentflow/TEAM.md` | 本文件 - 架构总览 |

## 双轨制

### 为什么双轨制？

- **FEATURES.json**: Git 持久化，跨会话保留，适合长期追踪
- **Task list**: Claude Code 原生，适合运行时调度和 UI 展示

### 同步规则

1. 启动时：FEATURES.json → Task list
2. 运行时：Task 完成 → 回写 FEATURES.json
3. 冲突时：Task list 为运行时权威

## 待完成功能

| ID | 功能 | 状态 | 实现者 |
|----|------|------|--------|
| FEAT-001 | API Key 安全存储 | partial | implementer-a |
| FEAT-006 | 安全扫描 | partial | implementer-b |
| FEAT-009 | 版本选择 | partial | implementer-c |
| FEAT-013 | 配置模板 | partial | implementer-a |
| FEAT-012 | 迁移导出 | pending | implementer-b |

## 启动命令

```bash
# 1. 创建 Team
TeamCreate("clawtools-team")

# 2. 生成 Team Lead
Agent(tool: team-lead, role: ...)

# 3. 生成 Implementer agents
Agent(tool: implementer-a, role: ...)
Agent(tool: implementer-b, role: ...)
Agent(tool: implementer-c, role: ...)

# 4. 生成 Sync Agent
Agent(tool: sync-writer, role: ...)

# 5. Team Lead 分配初始任务
SendMessage(to: "implementer-a", task: FEAT-001)
SendMessage(to: "implementer-b", task: FEAT-006)
SendMessage(to: "implementer-c", task: FEAT-009)
```

## 质量门禁

| 检查项 | 命令 | 标准 |
|--------|------|------|
| TypeScript | `npm run typecheck` | 通过 |
| ESLint | `npm run lint` | 无 warnings |
| 代码清洁 | 人工审查 | 无 console.log/debugger |

## 退出条件

- 所有 P0/P1 features status="pass"
- Task list 无 in_progress 任务
- 无 open P0/P1 bug

## 旧架构保留

`scripts/init.sh` 保留用于：
- 非 Agent 模式的项目初始化
- 独立的单任务执行
- 调试和备用

---

**迁移日期**: 2026-03-25
**版本**: v3.0 → v4.0 (Agent Teams)
