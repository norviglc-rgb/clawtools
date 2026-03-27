# 08 Agent Workflows

更新时间：2026-03-27

本文件定义 Claude Code 的自动开发工作流，以及 Codex 的人工/定时监督工作流。

## Workflow A：Claude 自动开发主流程

1. `team-lead` 读取 `07-agent-team-taskboard.md`
2. 按依赖拆成可独立执行的任务
3. 分配给对应 implementer
4. implementer 实现后提交完成包
5. `team-lead` 检查完成定义
6. 通过后状态转 `review_ready`
7. 等待 Codex 或自动验证结果
8. 验证通过后转 `done`

### 完成包模板

- 当前状态
- 修改文件
- 验证命令
- 验证结果
- 风险说明
- 回滚点

## Workflow B：Codex 定时监督流程

### 频率

- 每日固定 2 次检查
  - 建议在本地工作日 `09:30` 与 `18:30`
- 每个里程碑结束后追加 1 次审查

### 检查内容

1. 任务状态是否真实
2. 验证结果是否存在
3. 是否出现超范围修改
4. 是否存在文档漂移
5. 是否存在安全或发布残余风险

### 输出

- `继续执行`
- `带条件继续`
- `暂停并修正`
- `阻塞上线`

## Workflow C：阻塞升级流程

触发条件：

- 任务阻塞 > 4 小时
- 同任务失败 >= 2 次
- Claude team 出现假阳性完成
- 出现安全、数据完整性、发布链路冲突

处理步骤：

1. Claude team-lead 生成阻塞摘要
2. Codex 审查阻塞原因
3. 决定：
  - 重拆任务
  - 调整 ownership
  - 降级为人工接管
  - 冻结发布任务

## Workflow D：发布前审查流程

1. Claude 跑完 Must 测试和主路径 smoke
2. Codex 对照 `04-validation-matrix.md` 抽检
3. Codex 给出阶段结论
4. 若存在 Must 缺口，回流 Workflow A
5. Must 全过后进入 Go/No-Go

## Workflow E：发布后复盘流程

1. Claude 汇总实现与验证摘要
2. Codex 汇总风险、偏航、返工、遗漏
3. 形成 D+1 / D+3 / D+7 复盘结论

## 钩子与门禁建议

优先使用 Claude Code 自身可用的 hook/任务门禁能力实现以下约束：

- 任务创建时：无 owner、无依赖、无输出物定义则拒绝创建
- 任务完成时：无验证证据则拒绝完成
- teammate 空闲时：若存在 blocked 风险未升级则提醒 team-lead

若 hook 能力不足，则至少由 CI 和 Codex 审查补位，不允许完全无门禁运行。

## 明确的协作边界

### Claude 不应做

- 自己批准自己的高风险任务
- 跳过验证直接关闭任务
- 修改文档结论来掩盖实现缺口

### Codex 不应做

- 代替 Claude 成为主开发者
- 在没有证据时给出“应该没问题”的放行结论
- 直接改变 Claude 的任务状态而不留痕
