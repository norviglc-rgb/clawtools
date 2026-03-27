# 04 Validation Matrix

更新时间：2026-03-27

说明：

- `Claude Auto`：由 Claude Code 在任务完成或里程碑时自动执行
- `Codex Review`：由 Codex 定时或阶段性人工复核
- `Evidence`：必须留痕的结果载体

## A. Must Cases

| Case ID | 场景 | 覆盖问题 | 执行方 | 通过标准 | Evidence | 结果 |
|---|---|---|---|---|---|---|
| V-M01 | Windows 安装更新不破坏本地目录 | CT-001 | Claude Auto + Codex Review | 不执行强制删除/重置，失败可恢复 | 命令结果 + 代码差异 + 审查结论 | 待测 |
| V-M02 | 默认安装流程不自动执行 `audit fix --force` | CT-002 | Claude Auto + Codex Review | 安装阶段只报告，不强制改锁文件 | `package.json`/脚本差异 | 待测 |
| V-M03 | 配置加载不执行任意 JS | CT-003 | Claude Auto + Codex Review | `config.js` 不被执行，系统给出迁移或阻断提示 | 单测 + 手工复核记录 | 待测 |
| V-M04 | `updateAppConfig` 特殊字符输入 | CT-004 | Claude Auto + Codex Review | SQL 成功且无注入副作用 | 单测/集成测试结果 | 待测 |
| V-M05 | API Key 配置链路（含缺失密钥） | CT-005 | Claude Auto + Codex Review | 有密钥成功保存，无密钥明确阻断 | 单测 + 流程截图/日志 | 待测 |
| V-M06 | 多次进入/退出 screen 后输入稳定 | CT-006 | Claude Auto | 键盘输入不失效、不异常退出 | smoke 结果 | 待测 |
| V-M07 | `npm run lint` 生效且能拦截错误 | CT-008 | Claude Auto + Codex Review | 真实检查、违规非零退出 | CI 结果 + 手工故障注入 | 待测 |
| V-M08 | `npm run test` 可执行且最小集通过 | CT-007 | Claude Auto + Codex Review | unit + smoke 可跑通 | CI 结果 | 待测 |
| V-M09 | `npm run typecheck` 与 `npm run build` 通过 | - | Claude Auto | 两项均通过 | 命令结果 | 待测 |
| V-M10 | Claude team 无“无证据完成”任务 | 执行治理 | Codex Review | 抽检任务均附验证结果、风险说明、回滚点 | 审查记录 | 待测 |
| V-M11 | shell supervisor 不再模拟写 `pass` | 执行治理 | Codex Review | 仓库内不再存在生效的假完成路径 | 代码审查记录 | 待测 |
| V-M12 | Codex 日检与里程碑审查按计划执行 | 治理节奏 | Codex Review | 至少完成 1 次日检 + 1 次里程碑审查 | 检查记录 | 待测 |

## B. Should Cases

| Case ID | 场景 | 覆盖问题 | 执行方 | 通过标准 | 结果 |
|---|---|---|---|---|---|
| V-S01 | 版本页回车选择符合用户预期 | CT-010 | Claude Auto | 回车选择当前光标项 | 待测 |
| V-S02 | 文档状态一致性 | CT-009 | Codex Review | 文档、代码、验证证据一致 | 待测 |
| V-S03 | Linux 安装最小路径可用 | 兼容性 | Claude Auto | 安装通过，诊断基本可用 | 待测 |
| V-S04 | macOS 安装最小路径可用 | 兼容性 | Claude Auto | 安装通过，诊断基本可用 | 待测 |

## C. 兼容性矩阵

| 平台 | 安装 | 配置 | 诊断 | 负责人 | 结果 |
|---|---|---|---|---|---|
| Windows PowerShell | Must | Must | Must | Claude + Codex | 待测 |
| Linux Bash | Must | Should | Should | Claude | 待测 |
| macOS Bash/Zsh | Must | Should | Should | Claude | 待测 |

## D. 发布前证据包

- 测试报告链接：`待补充`
- CI 构建链接：`待补充`
- 已知问题清单：`待补充`
- 豁免项与负责人：`待补充`
- Codex 阶段审查记录：`待补充`
- Go/No-Go 审查结论：`待补充`
