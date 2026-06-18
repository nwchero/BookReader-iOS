#!/usr/bin/env bash
# build_monitor.sh - Monitor GitHub Actions build status for BookReader-iOS
# Usage: ./build_monitor.sh

set -e

REPO_OWNER="nwchero"
REPO_NAME="BookReader-iOS"
WORKFLOW_FILE="build-ios.yml"
GITHUB_TOKEN="${GITHUB_TOKEN:-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}"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="${PROJECT_DIR}/build_monitor.log"

AUTH_HEADER="Authorization: Bearer ${GITHUB_TOKEN}"
API_HEADER="Accept: application/vnd.github+json"
API_VERSION="X-GitHub-Api-Version: 2022-11-28"
API_BASE="https://api.github.com"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=============================================="
log "开始监控 GitHub Actions 构建 - ${REPO_OWNER}/${REPO_NAME}"
log "工作流: ${WORKFLOW_FILE}"
log "=============================================="

log ""
log "[1/4] 获取最近的 workflow runs..."
RUNS_RESPONSE=$(curl -sSL \
    -H "${AUTH_HEADER}" \
    -H "${API_HEADER}" \
    -H "${API_VERSION}" \
    "${API_BASE}/repos/${REPO_OWNER}/${REPO_NAME}/actions/workflows/${WORKFLOW_FILE}/runs?per_page=5")

TOTAL_COUNT=$(echo "$RUNS_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('total_count',0))" 2>/dev/null || echo "0")
log "工作流总运行次数: ${TOTAL_COUNT}"

LATEST_RUN=$(echo "$RUNS_RESPONSE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
runs = d.get('workflow_runs', [])
if runs:
    r = runs[0]
    print(json.dumps({
        'id': r.get('id'),
        'status': r.get('status'),
        'conclusion': r.get('conclusion'),
        'branch': r.get('head_branch'),
        'created_at': r.get('created_at'),
        'updated_at': r.get('updated_at'),
        'run_number': r.get('run_number'),
        'html_url': r.get('html_url'),
        'display_title': r.get('display_title'),
    }, ensure_ascii=False))
" 2>/dev/null)

log ""
log "[2/4] 最新构建信息:"
log "  Run ID:        $(echo "$LATEST_RUN" | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])")"
log "  Run #:         $(echo "$LATEST_RUN" | python3 -c "import sys,json;print(json.load(sys.stdin)['run_number'])")"
log "  分支:          $(echo "$LATEST_RUN" | python3 -c "import sys,json;print(json.load(sys.stdin)['branch'])")"
log "  标题:          $(echo "$LATEST_RUN" | python3 -c "import sys,json;print(json.load(sys.stdin)['display_title'])")"
log "  状态(status):  $(echo "$LATEST_RUN" | python3 -c "import sys,json;print(json.load(sys.stdin)['status'])")"
log "  结论:          $(echo "$LATEST_RUN" | python3 -c "import sys,json;print(json.load(sys.stdin)['conclusion'])")"
log "  创建时间:      $(echo "$LATEST_RUN" | python3 -c "import sys,json;print(json.load(sys.stdin)['created_at'])")"
log "  更新时间:      $(echo "$LATEST_RUN" | python3 -c "import sys,json;print(json.load(sys.stdin)['updated_at'])")"
log "  链接:          $(echo "$LATEST_RUN" | python3 -c "import sys,json;print(json.load(sys.stdin)['html_url'])")"

RUN_ID=$(echo "$LATEST_RUN" | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])")
STATUS=$(echo "$LATEST_RUN" | python3 -c "import sys,json;print(json.load(sys.stdin)['status'])")
CONCLUSION=$(echo "$LATEST_RUN" | python3 -c "import sys,json;print(json.load(sys.stdin)['conclusion'])")
CREATED_AT=$(echo "$LATEST_RUN" | python3 -c "import sys,json;print(json.load(sys.stdin)['created_at'])")

QUEUE_ELAPSED=$(python3 -c "
from datetime import datetime, timezone
created = datetime.fromisoformat('${CREATED_AT}'.replace('Z','+00:00'))
now = datetime.now(timezone.utc)
delta = now - created
h = int(delta.total_seconds() // 3600)
m = int((delta.total_seconds() % 3600) // 60)
s = int(delta.total_seconds() % 60)
print(f'{h}小时 {m}分钟 {s}秒 (总 {int(delta.total_seconds())} 秒)')
" 2>/dev/null || echo "未知")

log ""
log "[3/4] 状态分析:"

case "${STATUS}" in
    queued)
        log "⏳ 构建仍在排队中..."
        log "   已排队时长: ${QUEUE_ELAPSED}"
        log "   请耐心等待，macOS runner 有时需要较长排队时间。"
        ;;
    in_progress|waiting|requested)
        log "🔄 构建正在进行中..."
        log "   已运行时长: ${QUEUE_ELAPSED}"
        ;;
    completed)
        case "${CONCLUSION}" in
            success)
                log "✅ 构建成功 (conclusion=success)"
                log ""
                log "下载 artifacts:"
                ARTS=$(curl -sSL \
                    -H "${AUTH_HEADER}" \
                    -H "${API_HEADER}" \
                    -H "${API_VERSION}" \
                    "${API_BASE}/repos/${REPO_OWNER}/${REPO_NAME}/actions/runs/${RUN_ID}/artifacts")
                ART_COUNT=$(echo "$ARTS" | python3 -c "import sys,json;print(json.load(sys.stdin).get('total_count',0))")
                log "   Artifacts 数量: ${ART_COUNT}"
                for i in $(seq 0 $((ART_COUNT - 1))); do
                    NAME=$(echo "$ARTS" | python3 -c "import sys,json; a=json.load(sys.stdin)['artifacts']; print(a[${i}]['name'])" 2>/dev/null)
                    SIZE=$(echo "$ARTS" | python3 -c "import sys,json; a=json.load(sys.stdin)['artifacts']; print(a[${i}]['size_in_bytes'])" 2>/dev/null)
                    SIZE_MB=$(python3 -c "print(round(${SIZE}/1048576,2))" 2>/dev/null)
                    log "   - ${NAME} (约 ${SIZE_MB} MB)"
                done
                log ""
                log "📦 用户可以在 GitHub Actions 页面下载 IPA:"
                log "   $(echo "$LATEST_RUN" | python3 -c "import sys,json;print(json.load(sys.stdin)['html_url'])")"
                ;;
            failure|cancelled|timed_out)
                log "❌ 构建失败 (conclusion=${CONCLUSION})"
                log ""
                log "=== 错误日志 ==="
                RUN_LOGS=$(curl -sSL \
                    -H "${AUTH_HEADER}" \
                    -H "${API_HEADER}" \
                    -H "${API_VERSION}" \
                    "${API_BASE}/repos/${REPO_OWNER}/${REPO_NAME}/actions/runs/${RUN_ID}/logs" 2>&1 | tail -n 80)
                log "${RUN_LOGS}"
                ;;
            *)
                log "ℹ️  构建结论: ${CONCLUSION}"
                ;;
        esac
        ;;
    *)
        log "ℹ️  当前状态: ${STATUS}"
        ;;
esac

log ""
log "[4/4] 完整详细报告已写入: ${LOG_FILE}"
log "=============================================="
