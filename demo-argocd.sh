#!/bin/bash

set -e

echo "=== Argo CD GitOps 시연 ==="
echo ""

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Argo CD UI 열기
echo -e "${BLUE}[1/6] Argo CD UI 열기${NC}"
echo "URL: https://localhost:8080"
echo "Username: admin"
echo "Password: $(cat /tmp/argocd-password.txt)"
open https://localhost:8080
sleep 3

# 현재 상태 확인
echo ""
echo -e "${BLUE}[2/6] 현재 상태 확인${NC}"
kubectl get pods -l app=laravel-api
argocd app get laravel-api --refresh
read -p "계속하려면 Enter..."

# Replica 증가 시연
echo ""
echo -e "${BLUE}[3/6] Replica 3 → 5로 증가${NC}"
cd /Users/a_hyeon/Documents/Study/Kub\&ArgoCD/k8s-argocd-demo/k8s-manifests/laravel
sed -i '' 's/replicas: 3/replicas: 5/' deployment.yaml

echo "변경 사항:"
git diff deployment.yaml

git add deployment.yaml
git commit -m "Demo: Scale laravel-api to 5 replicas"
git push origin main

echo ""
echo -e "${YELLOW}→ Argo CD UI에서 Out of Sync 확인 (약 3분 대기 또는 수동 Refresh)${NC}"
echo -e "${YELLOW}→ Sync 버튼 클릭하여 배포${NC}"
read -p "Sync 완료 후 Enter..."

# 변경 확인
echo ""
kubectl get pods -l app=laravel-api
read -p "Pod 5개 확인 후 Enter..."

# 이미지 버전 변경 시연
echo ""
echo -e "${BLUE}[4/6] 이미지 버전 변경 (v1.10.1 → latest)${NC}"
sed -i '' 's/traefik\/whoami:v1.10.1/traefik\/whoami:latest/' deployment.yaml

git add deployment.yaml
git commit -m "Demo: Update image to latest"
git push origin main

echo -e "${YELLOW}→ Argo CD UI에서 변경 감지 및 Sync${NC}"
read -p "Sync 완료 후 Enter..."

# 버그 버전 배포 시연
echo ""
echo -e "${BLUE}[5/6] 버그 버전 배포 (잘못된 이미지)${NC}"
sed -i '' 's|image: .*|image: nginx:nonexistent-tag|' deployment.yaml

git add deployment.yaml
git commit -m "Demo: Deploy buggy version (wrong image)"
git push origin main

argocd app sync laravel-api
sleep 10

echo ""
echo -e "${RED}→ Argo CD UI에서 Degraded 상태 확인${NC}"
kubectl get pods -l app=laravel-api
read -p "에러 확인 후 Enter..."

# 롤백 시연
echo ""
echo -e "${BLUE}[6/6] 원클릭 롤백 시연${NC}"
echo -e "${YELLOW}옵션 1) Argo CD UI에서:${NC}"
echo "  Applications → laravel-api → History and Rollback 탭"
echo "  → 이전 버전 선택 → Rollback 버튼 클릭"
echo ""
echo -e "${YELLOW}옵션 2) CLI로 롤백:${NC}"
echo "  argocd app history laravel-api"
echo "  argocd app rollback laravel-api <revision-id>"
echo ""
read -p "롤백 방법을 선택하고 실행... (Enter to continue)"

# CLI로 롤백 실행
argocd app history laravel-api
echo ""
read -p "롤백할 revision ID 입력: " revision_id
echo "Rolling back to revision $revision_id..."
time argocd app rollback laravel-api $revision_id

sleep 5
kubectl get pods -l app=laravel-api

echo ""
echo -e "${GREEN}=== 시연 완료! ===${NC}"
echo ""
echo "주요 포인트:"
echo "1. ✅ Git Push → Argo CD 자동 감지 (기본 3분, 수동 Refresh 즉시)"
echo "2. ✅ UI에서 실시간 배포 상태 확인 (Resource Tree)"
echo "3. ✅ Rolling Update 무중단 배포"
echo "4. ✅ 원클릭 롤백 (15-30초)"
echo "5. ✅ 전체 배포 히스토리 추적"
echo ""
echo "Argo CD vs Traditional 배포:"
echo "- 롤백 속도: 15초 vs 5-10분 (20-40배 빠름)"
echo "- 배포 추적: Git 커밋 기반 완벽한 추적"
echo "- 선언적 배포: 원하는 상태를 Git에 정의"
