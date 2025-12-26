#!/bin/bash
# ============================================================================
# NEG Cleanup Script (Parallel)
# ============================================================================
# GKE destroy 전에 Load Balancer 백엔드 서비스에서 NEG 제거 후 NEG 삭제
# 병렬 처리로 빠른 삭제
# 사용법: ./cleanup-neg.sh <project_id>
# ============================================================================

PROJECT_ID="${1:-kdt2-final-project-t1}"
ZONES=("asia-northeast3-a" "asia-northeast3-b" "asia-northeast3-c")

echo "============================================"
echo "NEG Cleanup Script (Parallel)"
echo "Project: ${PROJECT_ID}"
echo "============================================"

# 1. 모든 k8s 관련 Backend Services에서 NEG 제거
echo ""
echo "[1/3] Removing NEGs from all backend services..."

BACKEND_SERVICES=$(gcloud compute backend-services list \
  --filter="name~k8s" \
  --format="value(name)" \
  --global \
  --project=${PROJECT_ID} 2>/dev/null || echo "")

if [ -n "$BACKEND_SERVICES" ]; then
  for bs in $BACKEND_SERVICES; do
    echo "  Clearing backends from: ${bs}"
    # 모든 백엔드 제거 (병렬)
    gcloud compute backend-services describe ${bs} --global --project=${PROJECT_ID} --format="json" 2>/dev/null | \
      jq -r '.backends[].group // empty' 2>/dev/null | \
      xargs -P 5 -I {} gcloud compute backend-services remove-backend ${bs} \
        --global --network-endpoint-group="{}" --project=${PROJECT_ID} --quiet 2>/dev/null || true
  done
fi

# 2. 모든 k8s 관련 NEG 삭제 (병렬)
echo ""
echo "[2/3] Deleting all k8s NEGs (parallel)..."

for zone in "${ZONES[@]}"; do
  echo "  Zone: ${zone}"

  # 해당 존의 모든 k8s NEG 목록
  NEGS=$(gcloud compute network-endpoint-groups list \
    --filter="name~k8s AND zone:${zone}" \
    --format="value(name)" \
    --project=${PROJECT_ID} 2>/dev/null || echo "")

  if [ -n "$NEGS" ]; then
    # 병렬 삭제 (최대 10개 동시)
    echo "$NEGS" | xargs -P 10 -I {} \
      gcloud compute network-endpoint-groups delete {} \
        --zone=${zone} \
        --project=${PROJECT_ID} \
        --quiet 2>/dev/null || true
    echo "    Deleted NEGs in ${zone}"
  fi
done &

# 백그라운드 작업 대기
wait

# 3. 남은 NEG 확인 및 재시도
echo ""
echo "[3/3] Verifying cleanup..."

REMAINING=$(gcloud compute network-endpoint-groups list \
  --filter="name~k8s" \
  --format="value(name)" \
  --project=${PROJECT_ID} 2>/dev/null | wc -l)

if [ "$REMAINING" -gt 0 ]; then
  echo "  Warning: ${REMAINING} NEGs still remaining (may be in use by LB)"
  echo "  They will be cleaned up when LB resources are deleted"
else
  echo "  All NEGs deleted successfully!"
fi

echo ""
echo "============================================"
echo "NEG cleanup completed!"
echo "============================================"
