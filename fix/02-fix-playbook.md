# ClawTools 修复手册（Fix Playbook）

更新时间：2026-03-27

说明：每条问题均包含证据、风险、修复方案、回归点、验收标准。问题 ID 与看板保持一致。

## CT-001 安装脚本破坏性更新路径（P0）

- 证据：
  - `scripts/install.ps1:86` `git reset --hard origin/master`
  - `scripts/install.ps1:89` `Remove-Item -Recurse -Force $InstallDir`
  - `scripts/install.ps1:94` `Remove-Item -Recurse -Force $InstallDir`
- 风险说明：
  - 可能覆盖用户本地改动，或在路径变量异常时误删目录。
- 修复方案：
  - 移除 `reset --hard` 与无确认递归删除。
  - 改为安全更新：`git fetch` + `git pull --ff-only`，失败时提示人工处理。
  - 删除前增加路径白名单校验（仅允许 `$HOME/.clawtools`）。
- 回归点：
  - 已安装目录存在本地改动时，脚本不应静默覆盖。
  - 更新失败时应有明确错误输出和恢复指引。
- 验收标准：
  - 脚本中不再出现 `reset --hard` 与无保护 `Remove-Item -Recurse -Force $InstallDir`。

## CT-002 `audit fix --force` 依赖漂移风险（P0）

- 证据：
  - `package.json:25` `"postinstall": "npm audit --audit-level=high || npm audit fix --force"`
  - `scripts/install.ps1:110` `npm audit fix --force 2>&1 | Out-Null`
- 风险说明：
  - 在安装阶段自动强制升级依赖，可能引入 breaking changes。
- 修复方案：
  - `postinstall` 改为只报告不自动修复（例如仅 `npm audit --audit-level=high`）。
  - 将修复动作转为显式命令（`npm run security:fix`）并要求人工触发。
- 回归点：
  - 全新安装不应自动改变锁文件语义。
- 验收标准：
  - 默认安装流程不包含 `audit fix --force`。

## CT-003 `vm.Script` 配置执行风险（P0）

- 证据：
  - `core/configurator.ts:77` `new vm.Script(...)` 执行 `config.js` 内容
- 风险说明：
  - 若配置文件被注入恶意代码，将在本地执行。
- 修复方案：
  - 默认只支持 JSON 配置（`config.json`/`settings.json`）。
  - 对 `config.js`：改为拒绝加载并给出迁移提示，或仅解析受限结构而非执行。
- 回归点：
  - 读取配置不会触发 JS 代码执行。
- 验收标准：
  - `loadConfig()` 不再使用 `vm.Script` 动态执行。

## CT-004 SQL 拼接风险（P0）

- 证据：
  - `db/index.ts:216` ``UPDATE app_config SET ${updates.join(', ')} WHERE id = 1``
- 风险说明：
  - 字符串拼接 SQL 易受输入污染，特殊字符可能破坏语句。
- 修复方案：
  - 改为参数化更新：每个字段使用占位符 `?`。
  - 为 `backupInterval`、`lastBackup`、`docsCloneDate` 增加输入校验。
- 回归点：
  - 含引号、分号、特殊字符的输入不影响 SQL 语义。
- 验收标准：
  - `updateAppConfig()` 不再拼接用户输入到 SQL 字符串。

## CT-005 API Key 加密前置条件缺失（P0）

- 证据：
  - `cli/screens/config.tsx:33` `configurator.encryptApiKey(apiKey)`
  - `cli/screens/config.tsx:48` `configurator.encryptApiKey(apiKey)`
  - `core/configurator.ts:110` `encryptApiKey` 在无 key 时抛错
- 风险说明：
  - 用户在配置界面输入 API Key 时可能直接失败。
- 修复方案：
  - 在 `ConfigScreen` 初始化时强制设置加密密钥来源（环境变量或交互输入）。
  - 若密钥缺失，阻断保存并提示。
- 回归点：
  - 无加密密钥时不会写入数据库且提示明确。
- 验收标准：
  - API Key 保存流程在正常配置下稳定成功。

## CT-006 TUI 输入监听竞争（P1）

- 证据：
  - `cli/App.tsx:62`, `cli/App.tsx:106` 全局 `removeAllListeners('data')`
  - `cli/screens/install.tsx:164`, `cli/screens/config.tsx:90`, `cli/screens/search.tsx:89` 等多处同模式
- 风险说明：
  - 一个 screen 卸载时可能清掉其他 screen 或父级监听。
- 修复方案：
  - 统一输入管理层（单一 keyboard dispatcher）。
  - 清理时只 `removeListener` 当前 handler，避免 `removeAllListeners`。
  - `setRawMode` 由入口统一管理。
- 回归点：
  - 多次进出 screen 后，按键行为稳定且无失效。
- 验收标准：
  - 代码中不再在 screen 级别使用 `removeAllListeners('data')`。

## CT-007 测试体系缺失（P1）

- 证据：
  - 仓库缺失 `tests/` 目录（审计时返回 `NO_TESTS_DIR`）
  - `FEATURES.json` 多处 `"tests": []`（如 `FEATURES.json:12`, `:23`, `:34`）
- 风险说明：
  - 回归无自动兜底，修复时容易引入新问题。
- 修复方案：
  - 建立最小测试基线：
  - 单测：`core/configurator`, `db/index` 关键路径
  - 集成：安装参数解析与失败分支
  - E2E smoke：主菜单导航与安装页关键键位流程
- 回归点：
  - CI 至少运行 typecheck + unit + smoke。
- 验收标准：
  - 存在可执行测试脚本并在 CI 中运行。

## CT-008 Lint 门禁缺失（P1）

- 证据：
  - `package.json:27` `"lint": "echo 'No lint configured' && exit 0"`
- 风险说明：
  - 不一致代码风格和明显错误无法在提交前拦截。
- 修复方案：
  - 引入 ESLint + TypeScript 规则，至少覆盖 `cli/`, `core/`, `db/`。
  - 将 `lint` 接入 CI 必跑流程。
- 回归点：
  - 故意引入未使用变量/明显错误可被 lint 拦截。
- 验收标准：
  - `npm run lint` 实际执行检查并在违规时非零退出。

## CT-009 文档状态漂移（P1）

- 证据：
  - `SPEC.md` 大量 `（待补充具体功能描述）`（如 `SPEC.md:63`, `:74`, `:85`）
  - `SPEC.md:273`, `SPEC.md:277` 为占位段落
  - `PROGRESS.md:9` 显示初始化完成，但同时 `PROGRESS.md:77` 完成率 `62%`
- 风险说明：
  - 团队基于文档做决策时可能误判项目状态。
- 修复方案：
  - 建立文档更新规则：以事实状态自动同步（脚本化）。
  - 去除占位文本，补齐每个 FEAT 的验收项与当前状态。
- 回归点：
  - 每次功能变更后 `SPEC/PROGRESS/FEATURES` 一致。
- 验收标准：
  - 文档不存在占位符，状态字段彼此一致。

## CT-010 安装与版本选择交互缺陷（P1）

- 证据：
  - `cli/screens/install.tsx:128-131` 版本页回车固定选取页首 `versionList[idx]`
  - `cli/screens/install.tsx:95` 平台页 `空格/回车` 即直接安装
- 风险说明：
  - 用户在版本页无法用光标明确选择，容易误装。
- 修复方案：
  - 增加版本页 `cursorIndex`，回车选择当前光标版本。
  - 平台页将“选择平台”和“开始安装”分离，降低误触风险。
- 回归点：
  - 不同页面键位行为一致、可预测。
- 验收标准：
  - 回车行为总是对应“当前选中项”，不再默认页首。
