# Agent Team Specification

## Agent Hierarchy

```
Human (Oversight Only)
        │
        ▼
┌─────────────────────────────────────────────────┐
│           Supervisor Agent (Master)                │
│  - Task assignment                               │
│  - Quality gates                                 │
│  - Self-correction                               │
│  - Progress tracking                             │
└─────────────────────────────────────────────────┘
           │           │           │
           ▼           ▼           ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐
    │  Coding  │ │  Testing  │ │    QA    │
    │  Agent   │ │   Agent   │ │   Agent  │
    └──────────┘ └──────────┘ └──────────┘
                        │
                        ▼
               ┌──────────────┐
               │   Recovery   │
               │    Agent     │
               └──────────────┘
```

## Supervisor Agent
- **Role**: Project coordination, task assignment
- **Instructions**: See SUPERVISOR.md or AGENTS/supervisor/CLAUDE.md
- **Trigger**: On push to develop, manual /supervisor start, scheduled every 6h
- **Exit**: All P0/P1 pass, coverage ≥ 80%, tests pass, no open P0/P1 bugs

## Coding Agent
- **Role**: Feature implementation
- **Instructions**: See AGENTS/coding/CLAUDE.md
- **Workflow**: Read FEATURES.json → Implement → Test → Typecheck → Update status → Commit

## Testing Agent
- **Role**: E2E testing
- **Instructions**: See AGENTS/testing/CLAUDE.md
- **Trigger**: After Coding Agent completes feature
- **Scope**: Critical user flows, no UI regressions

## QA Agent
- **Role**: Code review
- **Instructions**: See AGENTS/qa/CLAUDE.md
- **Focus**: TypeScript correctness, error handling, security

## Recovery Agent
- **Role**: Auto-repair
- **Instructions**: See AGENTS/recovery/CLAUDE.md
- **Trigger**: When npm test fails, typecheck fails
- **Scope**: npm deps, TS errors, config corruption

## Agent Communication
- **FEATURES.json**: Task status, assignment
- **PROGRESS.md**: Human-readable log
- **CHECKPOINTS/**: Periodic snapshots
