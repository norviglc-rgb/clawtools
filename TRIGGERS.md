# 触发机制

## 触发类型

### 1. Git Push (主要)
```yaml
on:
  push:
    branches: [develop, main]
```
push 到 develop → 触发 Supervisor

### 2. 手动触发
```bash
bash .agentflow/supervisor-loop.sh start
```

### 3. 定时触发 (备用)
```bash
# crontab -e
0 */6 * * * cd /path/to/project && bash .agentflow/supervisor-loop.sh start
```

## 循环状态机

```
IDLE → RUNNING → PAUSED → DONE
                    ↓
                  ERROR
```

## 状态转换

| 命令 | 当前状态 | 下一状态 |
|------|----------|----------|
| start | IDLE | RUNNING |
| pause | RUNNING | PAUSED |
| resume | PAUSED | RUNNING |
| exit (条件满足) | RUNNING | DONE |
| exit (错误) | RUNNING | ERROR |
