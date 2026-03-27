# ClawTools 问题看板

更新时间：2026-03-27

状态定义：`待修复` / `修复中` / `已修复`

| ID | 严重级别 | 模块 | 问题 | 影响 | 建议优先级 | 状态 |
|---|---|---|---|---|---|---|
| CT-001 | Critical | `scripts/install.ps1` | 更新路径包含 `git reset --hard` 与安装目录强制删除重拉 | 可能破坏用户本地修改或误删目录内容 | P0 | 待修复 |
| CT-002 | High | `package.json`, `scripts/install.ps1` | 自动执行 `npm audit fix --force` | 引入不可预期升级与行为漂移，影响稳定性 | P0 | 待修复 |
| CT-003 | Critical | `core/configurator.ts` | 使用 `vm.Script` 直接执行 `config.js` 内容 | 打开本地代码执行面，配置文件被污染可导致任意代码执行 | P0 | 待修复 |
| CT-004 | Critical | `db/index.ts` | `updateAppConfig` 采用字符串拼接构造 SQL | 存在 SQL 注入与特殊字符破坏语句风险 | P0 | 待修复 |
| CT-005 | High | `cli/screens/config.tsx` | 调用 `encryptApiKey` 前未确保 `setEncryptionKey` 已执行 | 运行时抛错，导致配置流程失败 | P0 | 待修复 |
| CT-006 | High | `cli/*` 多 screen | 多处 `setRawMode/removeAllListeners('data')` 并发清理 | 可能误删其他监听，导致键盘事件失效或退出异常 | P1 | 待修复 |
| CT-007 | High | 全项目 | 无 `tests/` 与自动化测试体系 | 无法保证回归质量，也不满足 80% 覆盖要求 | P1 | 待修复 |
| CT-008 | Medium | `package.json` | `lint` 脚本为空实现 | 无静态质量门禁，问题只能在运行时暴露 | P1 | 待修复 |
| CT-009 | Medium | `SPEC.md`, `PROGRESS.md`, `FEATURES.json` | 文档含大量占位和状态不一致信息 | 降低文档可信度，影响协作与排期判断 | P1 | 待修复 |
| CT-010 | Medium | `cli/screens/install.tsx` | 版本页回车默认选取页首版本，交互不直观 | 用户可能误装版本，增加安装失败/返工概率 | P1 | 待修复 |

## 当前优先处理顺序

1. CT-001
2. CT-003
3. CT-004
4. CT-002
5. CT-005
6. CT-006
7. CT-007
8. CT-008
9. CT-010
10. CT-009
