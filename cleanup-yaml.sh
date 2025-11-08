#!/bin/bash

# YAML 파일에서 불필요한 메타데이터 제거 스크립트

set -e

cleanup_yaml() {
    local file=$1
    echo "Cleaning up: $file"

    # yq를 사용하여 불필요한 필드 제거
    yq eval 'del(.metadata.creationTimestamp,
                 .metadata.generation,
                 .metadata.resourceVersion,
                 .metadata.uid,
                 .metadata.selfLink,
                 .metadata.managedFields,
                 .status)' -i "$file"

    # Deployment의 경우 추가 정리
    if grep -q "kind: Deployment" "$file"; then
        yq eval 'del(.spec.template.metadata.creationTimestamp)' -i "$file"
    fi

    # Service의 경우 추가 정리
    if grep -q "kind: Service" "$file"; then
        yq eval 'del(.spec.clusterIP, .spec.clusterIPs)' -i "$file"
    fi
}

# yq 설치 확인
if ! command -v yq &> /dev/null; then
    echo "yq가 설치되지 않았습니다. Homebrew로 설치합니다..."
    brew install yq
fi

# 모든 YAML 파일 정리
echo "=== YAML 파일 정리 시작 ==="
for file in k8s-manifests/{laravel,spring}/*.yaml; do
    if [ -f "$file" ]; then
        cleanup_yaml "$file"
    fi
done

echo ""
echo "=== 정리 완료! ==="
echo "다음 위치의 YAML 파일들이 정리되었습니다:"
find k8s-manifests -name "*.yaml" -type f
