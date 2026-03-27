# ClawTools 项目结构与健康度地图

更新时间：2026-03-27

## 1) 结构总览

- `cli/`：Ink TUI 入口与各功能屏幕（安装、配置、诊断、备份、搜索、扫描、迁移）
- `core/`：核心业务能力（安装器、配置器、诊断器、探测、迁移、搜索、备份）
- `db/`：SQLite 数据访问层（`better-sqlite3`）与配置/历史/备份记录
- `config/`：Provider 预设与推荐配置
- `scripts/`：跨平台安装脚本与初始化脚本
- `docs/`：项目文档（目前内容较少，主要文档位于仓库根）

## 2) 关键入口与数据流

- CLI 入口：`cli/index.tsx`
  - 启动时调用 `detectSystem()`，渲染主菜单 `App`
- 主菜单：`cli/App.tsx`
  - 进入各 screen，screen 再调用 `core/*` 能力
- 安装链路：`cli/screens/install.tsx` -> `core/installer.ts`
  - 涵盖 native/docker/wsl 三种安装路径
- 配置链路：`cli/screens/config.tsx` -> `core/configurator.ts` + `db/index.ts`
  - API Key 加密写入 DB，Provider 配置持久化
- 诊断链路：`cli/screens/doctor.tsx` -> `core/doctor.ts` + `core/detector.ts`
- 文档搜索链路：`cli/screens/search.tsx` -> `core/search.ts`

## 3) 依赖关系摘要

- 运行时核心依赖：`ink`, `react`, `better-sqlite3`, `flexsearch`, `semver`, `tar`
- 构建方式：`tsc` 输出至 `bin/`，再执行 `scripts/fix-imports.js`
- 数据落盘路径：
  - `~/.clawtools/clawtools.db`（本工具数据库）
  - `~/.openclaw/*`（OpenClaw 配置）

## 4) 当前健康度摘要

- 编译与类型检查：
  - `npm run typecheck` 通过
  - `npm run build` 通过
- 主要风险面：
  - 安装脚本存在破坏性命令
  - 配置执行与 SQL 拼接存在安全风险
  - TUI 输入处理存在全局监听清理冲突
  - 测试与 lint 质量门禁缺失
- 文档一致性：
  - `SPEC.md` 与 `PROGRESS.md` 含大量占位与状态漂移信息

## 5) 审计边界说明

- 本次分析仅覆盖项目自身源码与脚本，不将 `node_modules/` 第三方代码计入项目缺陷归因。
- 详细问题清单见 `01-issue-board.md`，可执行修复见 `02-fix-playbook.md`，安全专项见 `03-security-audit.md`。
