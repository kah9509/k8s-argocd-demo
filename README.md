# Argo CD GitOps Demo

K3d 클러스터에서 Argo CD를 사용한 GitOps 기반 배포 자동화 데모

## 📋 구성 요소

- **K3d 클러스터**: 로컬 Kubernetes 환경 (demo-cluster)
- **Argo CD**: GitOps 배포 도구
- **Applications**:
  - laravel-api (3 replicas)
  - spring-api (3 replicas)

## 🚀 설치 완료 항목

✅ K3d 클러스터 실행 중
✅ Argo CD 설치 및 실행
✅ Argo CD UI 접근 설정 (Port-forward)
✅ Argo CD CLI 설치 및 로그인
✅ Git Repository 연결
✅ Applications 생성 및 배포

## 🔑 Argo CD 접속 정보

```bash
URL: https://localhost:8080
Username: admin
Password: R7OeQ6rNDHyqDvRu
```

> 비밀번호는 `/tmp/argocd-password.txt` 에도 저장되어 있습니다.

## 📂 프로젝트 구조

```
k8s-argocd-demo/
├── k8s-manifests/
│   ├── laravel/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── spring/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── base/
├── demo-argocd.sh          # 시연 스크립트
├── checklist.sh            # 환경 체크 스크립트
├── cleanup-yaml.sh         # YAML 정리 스크립트
└── README.md
```

## 🎯 시연 준비

### 1. 환경 체크

```bash
./checklist.sh
```

모든 항목이 ✓ 표시되어야 합니다.

### 2. Argo CD UI 접속 확인

브라우저에서 https://localhost:8080 접속하여 로그인

### 3. 현재 상태 확인

```bash
# Applications 목록
argocd app list

# Pods 상태
kubectl get pods

# Services 상태
kubectl get services
```

## 🎬 시연 시나리오

### 자동 시연 스크립트 실행

```bash
./demo-argocd.sh
```

### 수동 시연 단계

#### 1단계: Replica Scale 변경

```bash
cd k8s-manifests/laravel/
sed -i '' 's/replicas: 3/replicas: 5/' deployment.yaml
git add deployment.yaml
git commit -m "Scale laravel-api to 5 replicas"
git push origin main
```

Argo CD UI에서:
- Out of Sync 상태 확인
- Sync 버튼 클릭
- Pod 개수 3 → 5로 증가 확인

#### 2단계: 이미지 버전 변경

```bash
sed -i '' 's/traefik\/whoami:v1.10.1/traefik\/whoami:latest/' deployment.yaml
git add deployment.yaml
git commit -m "Update image to latest"
git push origin main
```

Argo CD UI에서 Rolling Update 과정 확인

#### 3단계: 버그 버전 배포

```bash
sed -i '' 's|image: .*|image: nginx:nonexistent-tag|' deployment.yaml
git add deployment.yaml
git commit -m "Deploy buggy version"
git push origin main

argocd app sync laravel-api
```

Argo CD UI에서:
- Health Status: Degraded 확인
- Pods: ImagePullBackOff 상태 확인

#### 4단계: 원클릭 롤백

**UI 방식:**
1. Applications → laravel-api
2. History and Rollback 탭
3. 이전 정상 버전 선택
4. Rollback 버튼 클릭
5. 약 15초 만에 복구 완료!

**CLI 방식:**
```bash
# 히스토리 확인
argocd app history laravel-api

# 특정 revision으로 롤백
argocd app rollback laravel-api <revision-id>

# 소요 시간 측정
time argocd app rollback laravel-api 2
```

## 📊 주요 시연 포인트

### 1. GitOps 워크플로우
- Git이 Single Source of Truth
- 모든 변경은 Git 커밋으로 추적
- 선언적 배포 방식

### 2. 실시간 모니터링
- Resource Tree에서 실시간 상태 확인
- Rolling Update 과정 시각화
- Health Check 자동화

### 3. 빠른 롤백
- **Traditional 배포**: 5-10분
- **Argo CD**: 15-30초
- **차이**: 20-40배 빠름!

### 4. 배포 히스토리
- 모든 배포 이력 추적
- Git 커밋과 연동
- 언제든 이전 버전으로 복원 가능

## 🛠️ 유용한 명령어

### Argo CD CLI

```bash
# Application 목록
argocd app list

# Application 상태 확인
argocd app get <app-name>

# 수동 Sync
argocd app sync <app-name>

# Refresh (Git 변경 감지)
argocd app get <app-name> --refresh

# 히스토리 확인
argocd app history <app-name>

# 롤백
argocd app rollback <app-name> <revision-id>

# Repository 목록
argocd repo list
```

### Kubectl

```bash
# Pods 확인
kubectl get pods -l app=laravel-api
kubectl get pods -l app=spring-api

# Services 확인
kubectl get services

# Argo CD Pods 확인
kubectl get pods -n argocd

# Logs 확인
kubectl logs -n argocd deployment/argocd-server
```

## 🔧 문제 해결

### Port-forward가 종료된 경우

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /tmp/argocd-port-forward.log 2>&1 &
echo $! > /tmp/argocd-port-forward.pid
```

### Application이 계속 OutOfSync인 경우

```bash
# 수동으로 Sync 강제 실행
argocd app sync <app-name> --force

# 또는 Prune을 활성화하여 Sync
argocd app sync <app-name> --prune
```

### Argo CD UI 접속 안 되는 경우

```bash
# Port-forward 재시작
pkill -f "port-forward.*argocd-server"
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Argo CD Server Pod 확인
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server
```

### 비밀번호 분실 시

```bash
# 초기 비밀번호 다시 확인
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

## 📚 추가 학습 자료

- [Argo CD 공식 문서](https://argo-cd.readthedocs.io/)
- [GitOps 원칙](https://www.gitops.tech/)
- [K3d 문서](https://k3d.io/)

## 🎓 시연 후 정리

```bash
# Applications 삭제 (클러스터는 유지)
argocd app delete laravel-api
argocd app delete spring-api

# Argo CD 완전 삭제
kubectl delete namespace argocd

# 클러스터 삭제
k3d cluster delete demo-cluster
```

## ✨ 핵심 메시지

**Argo CD를 사용하면:**
- ✅ 배포 속도 향상 (롤백 20-40배 빠름)
- ✅ 완벽한 배포 추적 (Git 기반)
- ✅ 선언적 배포 (원하는 상태 정의)
- ✅ 자동화된 복구 (Self-Healing)
- ✅ 실시간 모니터링 (UI)

---

**Created**: 2025-11-08
**Repository**: https://github.com/kah9509/k8s-argocd-demo
