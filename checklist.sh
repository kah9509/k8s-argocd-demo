#!/bin/bash

echo "=== Argo CD 시연 준비 체크리스트 ==="
echo ""

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

check_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
}

# 1. 클러스터 상태
echo -n "□ K3d 클러스터 실행 중: "
k3d cluster list | grep -q "demo-cluster"
check_status $?

# 2. Argo CD Pod 실행
echo -n "□ Argo CD Pods 실행 중: "
kubectl get pods -n argocd 2>/dev/null | grep -q "Running"
check_status $?

# 3. UI 접근
echo -n "□ Argo CD UI 접근 가능: "
curl -k -s https://localhost:8080 > /dev/null 2>&1
check_status $?

# 4. Port-forward 실행
echo -n "□ Port-forward 실행 중: "
if [ -f /tmp/argocd-port-forward.pid ]; then
    pid=$(cat /tmp/argocd-port-forward.pid)
    ps -p $pid > /dev/null 2>&1
    check_status $?
else
    echo -e "${RED}✗ (PID 파일 없음)${NC}"
fi

# 5. Argo CD CLI 설치
echo -n "□ Argo CD CLI 설치됨: "
command -v argocd > /dev/null 2>&1
check_status $?

# 6. Git Repository 연결
echo -n "□ Git Repository 등록: "
argocd repo list 2>/dev/null | grep -q "Successful"
check_status $?

# 7. Applications 생성
echo -n "□ laravel-api Application: "
argocd app get laravel-api > /dev/null 2>&1
check_status $?

echo -n "□ spring-api Application: "
argocd app get spring-api > /dev/null 2>&1
check_status $?

# 8. Deployment 상태
echo -n "□ laravel-api Pods Running: "
kubectl get pods -l app=laravel-api 2>/dev/null | grep -q "Running"
check_status $?

echo -n "□ spring-api Pods Running: "
kubectl get pods -l app=spring-api 2>/dev/null | grep -q "Running"
check_status $?

# 9. 시연 스크립트
echo -n "□ 시연 스크립트 존재: "
[ -f "/Users/a_hyeon/Documents/Study/Kub&ArgoCD/k8s-argocd-demo/demo-argocd.sh" ]
check_status $?

echo ""
echo "=== 추가 확인 사항 ==="
echo ""

# Argo CD 로그인 정보
if [ -f /tmp/argocd-password.txt ]; then
    echo "Argo CD 로그인 정보:"
    echo "  URL: https://localhost:8080"
    echo "  Username: admin"
    echo "  Password: $(cat /tmp/argocd-password.txt)"
else
    echo "⚠️  Argo CD 비밀번호 파일 없음"
fi

echo ""

# Git Repository URL
repo_url=$(argocd repo list 2>/dev/null | grep github | awk '{print $3}')
if [ -n "$repo_url" ]; then
    echo "Git Repository: $repo_url"
else
    echo "⚠️  Git Repository 정보 없음"
fi

echo ""

# Pod 개수
laravel_pods=$(kubectl get pods -l app=laravel-api --no-headers 2>/dev/null | wc -l | tr -d ' ')
spring_pods=$(kubectl get pods -l app=spring-api --no-headers 2>/dev/null | wc -l | tr -d ' ')
echo "현재 Pod 개수:"
echo "  laravel-api: $laravel_pods"
echo "  spring-api: $spring_pods"

echo ""

# Argo CD Application 상태
echo "Application 상태:"
argocd app list 2>/dev/null || echo "  ⚠️  Argo CD CLI 로그인 필요"

echo ""
echo "=== 시연 시작 전 체크 ==="
echo "1. 브라우저에서 https://localhost:8080 접속 가능한지 확인"
echo "2. Argo CD UI에 로그인 (admin / $(cat /tmp/argocd-password.txt 2>/dev/null || echo 'PASSWORD'))"
echo "3. Applications 페이지에서 laravel-api, spring-api 확인"
echo "4. Git repository 쓰기 권한 확인: git push 테스트"
echo ""
echo "시연 스크립트 실행:"
echo "  chmod +x /Users/a_hyeon/Documents/Study/Kub\&ArgoCD/k8s-argocd-demo/demo-argocd.sh"
echo "  /Users/a_hyeon/Documents/Study/Kub\&ArgoCD/k8s-argocd-demo/demo-argocd.sh"
