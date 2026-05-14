#!/bin/bash

# BookReader-iOS Build Monitor Script
# 检查 GitHub Actions 构建进度

REPO="nwchero/BookReader-iOS"
# 从环境变量获取 GitHub Token，避免硬编码
TOKEN="${GITHUB_TOKEN:-}"
LOG_FILE="/workspace/BookReader-iOS/build_monitor.log"

echo "=== 开始检查 GitHub Actions 构建进度 ===" | tee "$LOG_FILE"
echo "仓库: $REPO" | tee -a "$LOG_FILE"
echo "时间: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# 获取最新的工作流运行
echo "正在获取最新工作流运行..." | tee -a "$LOG_FILE"

# 使用 GitHub API 获取工作流运行
if [ -n "$TOKEN" ]; then
  WORKFLOW_RUNS=$(curl -s -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$REPO/actions/runs?per_page=1")
else
  # 如果没有令牌，尝试公开访问
  WORKFLOW_RUNS=$(curl -s -L \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$REPO/actions/runs?per_page=1")
fi

if [ $? -ne 0 ]; then
  echo "错误: 无法连接到 GitHub API" | tee -a "$LOG_FILE"
  exit 1
fi

# 使用 Python 解析 JSON
python3 -c "
import json
from datetime import datetime

data = json.loads('''$WORKFLOW_RUNS''')

if 'workflow_runs' in data and len(data['workflow_runs']) > 0:
    run = data['workflow_runs'][0]
    
    print('')
    print('=== 最新构建信息 ===')
    print(f'Run ID: {run[\"id\"]}')
    print(f'状态 (status): {run[\"status\"]}')
    print(f'结论 (conclusion): {run[\"conclusion\"]}')
    print(f'创建时间: {run[\"created_at\"]}')
    print(f'更新时间: {run[\"updated_at\"]}')
    print(f'详情链接: {run[\"html_url\"]}')
    print(f'Artifacts 链接: {run[\"artifacts_url\"]}')
    print('')
    
    # 计算运行时长
    created = datetime.fromisoformat(run['created_at'][:-1])
    now = datetime.utcnow()
    elapsed = now - created
    elapsed_min = int(elapsed.total_seconds() // 60)
    elapsed_sec = int(elapsed.total_seconds() % 60)
    print(f'已运行: {elapsed_min}分{elapsed_sec}秒')
    print('')
    
    print('=== 构建结果分析 ===')
    
    if run['status'] == 'queued':
        print('⚠️  构建正在排队中...')
        print(f'已排队时长: {elapsed_min}分{elapsed_sec}秒')
    elif run['status'] == 'in_progress':
        print('⚠️  构建正在进行中...')
        print(f'已运行: {elapsed_min}分{elapsed_sec}秒')
    elif run['conclusion'] == 'success':
        print('✅ 构建成功!')
        print('📱 您可以从 GitHub Actions 下载 IPA 文件')
        print(f'下载链接: {run[\"html_url\"]}')
    elif run['conclusion'] == 'failure':
        print('❌ 构建失败!')
        print(f'查看日志: {run[\"logs_url\"]}')
    else:
        print(f'📋 构建状态: {run[\"conclusion\"]}')
    print('')
    print('=== 检查完成 ===')
" | tee -a "$LOG_FILE"
