# 为 ClawTools 贡献

感谢您对 ClawTools 贡献的兴趣！

## 行为准则

本项目遵守所有贡献者都应遵循的行为准则。请在所有互动中保持尊重和建设性。

## 如何贡献？

### 报告 Bug

创建 Bug 报告之前：
- 检查 [Issue 追踪器](https://github.com/norviglc-rgb/clawtools/issues) 避免重复
- 确认 Bug 存在于最新版本
- 收集您的环境信息（操作系统、Node.js 版本等）

提交 Bug 报告时，请包含：
- 清晰、描述性的标题
- 重现问题的步骤
- 预期与实际行为
- 相关日志或错误消息
- 您的环境详情

### 建议功能

欢迎提出功能建议！请：
- 创建新 Issue 前先搜索现有 Issue
- 提供清晰的使用场景和预期行为
- 解释此功能对用户的益处

### 提交 Pull Request

1. **Fork 仓库**
   ```bash
   git clone https://github.com/norviglc-rgb/clawtools.git
   cd clawtools
   ```

2. **创建功能分支**
   ```bash
   git checkout -b feature/您的功能名称
   # 或
   git checkout -b fix/您的修复名称
   ```

3. **设置开发环境**
   ```bash
   npm install
   npm run build
   ```

4. **进行修改**
   - 遵循现有代码风格
   - 编写清晰、描述性的提交消息
   - 如有适用，添加测试
   - 按需更新文档

5. **测试您的修改**
   ```bash
   npm run typecheck
   npm start
   ```

6. **提交并推送**
   ```bash
   git add .
   git commit -m "Add: 描述性提交消息"
   git push origin feature/您的功能名称
   ```

7. **打开 Pull Request**
   - 填写 PR 模板
   - 关联相关 Issue
   - 等待审核

## 开发环境设置

### 前置要求

- Node.js 20+
- npm 或 pnpm

### 项目结构

```
clawtools/
├── cli/           # TUI 界面
│   └── screens/   # UI 界面
├── core/          # 业务逻辑
├── config/        # 配置预设
├── db/            # 数据库层
├── i18n/          # 国际化
└── scripts/       # 安装脚本
```

### 代码规范

- 所有新代码使用 TypeScript
- 遵循现有代码格式
- 使用清晰的变量/函数名称编写自文档化代码
- 为公共 API 添加 JSDoc 注释
- 保持函数小而专注

### 测试

运行测试套件：
```bash
npm run test
```

### 提交消息格式

```
类型(范围): 描述

类型：
- Add: 新功能
- Fix: Bug 修复
- Update: 更新现有功能
- Refactor: 代码重构
- Docs: 文档更改
- Style: 格式调整，无代码变更
- Test: 添加测试
- Chore: 维护任务
```

示例：
```
Add(config): 添加 MiniMax provider 支持
Fix(installer): 优雅处理 Node.js 缺失情况
Docs(readme): 更新安装说明
```

## 分支策略

- `main` - 稳定发布分支
- `develop` - 开发分支（如需要）
- `feature/*` - 新功能分支
- `fix/*` - Bug 修复分支

## 许可证

贡献即表示您同意您的贡献将采用 MIT 许可证。

## 问题？

欢迎：
- 打开 Issue 提问
- 查看现有讨论
- 联系维护者

感谢您为 ClawTools 贡献！
