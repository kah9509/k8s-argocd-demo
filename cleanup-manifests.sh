#!/bin/bash

# Argo CD용 매니페스트 정리 스크립트
# 불필요한 메타데이터를 제거하고 깨끗한 YAML 파일을 생성합니다

set -e

echo "=== Kubernetes 매니페스트 정리 시작 ==="

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# 매니페스트 정리 함수
clean_manifest() {
    local input_file=$1
    local output_file=$2
    local resource_type=$3

    echo -e "${BLUE}처리 중: $input_file${NC}"

    # yq를 사용하여 불필요한 필드 제거
    # yq가 없으면 수동으로 정리
    if command -v yq &> /dev/null; then
        yq eval 'del(.metadata.uid,
                     .metadata.resourceVersion,
                     .metadata.generation,
                     .metadata.creationTimestamp,
                     .metadata.managedFields,
                     .metadata.selfLink,
                     .status)' "$input_file" > "$output_file"

        # Deployment인 경우 추가 정리
        if [ "$resource_type" == "deployment" ]; then
            yq eval 'del(.spec.template.metadata.creationTimestamp)' -i "$output_file"
        fi

        # Service인 경우 추가 정리
        if [ "$resource_type" == "service" ]; then
            yq eval 'del(.spec.clusterIP, .spec.clusterIPs)' -i "$output_file"
        fi
    else
        # yq가 없으면 grep으로 수동 정리
        grep -v -E "uid:|resourceVersion:|generation:|creationTimestamp:|managedFields:|selfLink:|status:" "$input_file" | \
        grep -v -E "clusterIP:|clusterIPs:" > "$output_file"
    fi

    echo -e "${GREEN}✓ 생성됨: $output_file${NC}"
}

# Laravel API 매니페스트 정리
clean_manifest \
    "k8s-manifests/laravel/deployment-raw.yaml" \
    "k8s-manifests/laravel/deployment.yaml" \
    "deployment"

clean_manifest \
    "k8s-manifests/laravel/service-raw.yaml" \
    "k8s-manifests/laravel/service.yaml" \
    "service"

# Spring API 매니페스트 정리
clean_manifest \
    "k8s-manifests/spring/deployment-raw.yaml" \
    "k8s-manifests/spring/deployment.yaml" \
    "deployment"

clean_manifest \
    "k8s-manifests/spring/service-raw.yaml" \
    "k8s-manifests/spring/service.yaml" \
    "service"

# raw 파일 삭제
rm -f k8s-manifests/laravel/*-raw.yaml
rm -f k8s-manifests/spring/*-raw.yaml

echo ""
echo -e "${GREEN}=== 매니페스트 정리 완료! ===${NC}"
echo ""
echo "생성된 파일:"
ls -lh k8s-manifests/laravel/
ls -lh k8s-manifests/spring/
