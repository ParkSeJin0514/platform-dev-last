# EKS Module

EKS 클러스터와 Managed Node Group을 생성합니다.

## 📋 생성되는 리소스

| 리소스 | 수량 | 설명 |
|--------|------|------|
| EKS Cluster | 1 | Kubernetes Control Plane |
| Managed Node Group | 1 | Worker Node 그룹 |
| Launch Template | 1 | Worker Node 설정 (Ubuntu 24.04) |
| Security Group | 2 | Cluster SG, Node SG |
| IAM Role | 2 | Cluster Role, Node Role |
| VPC CNI Add-on | 1 | Pod 네트워킹 (Secondary IP 모드) |

---

## ✨ 주요 기능

- **Ubuntu 24.04 EKS AMI**: SSM Parameter Store에서 자동 조회
- **IMDSv2 강제**: SSRF 공격 방지
- **EBS 암호화**: 볼륨 자동 암호화
- **롤링 업데이트**: max_unavailable_percentage 설정
- **VPC CNI Add-on**: Secondary IP 모드로 Pod 네트워킹 관리

---

## 🌐 VPC CNI 네트워킹

### Secondary IP 모드 (기본값)

| 항목 | 값 |
|------|-----|
| Pod IP 할당 방식 | ENI에 Secondary IP 할당 |
| 노드당 최대 Pod 수 | 인스턴스 타입에 따라 결정 |
| 서브넷 권장 크기 | /24 이상 |

**인스턴스별 최대 Pod 수 (Secondary IP 모드)**

| 인스턴스 타입 | ENI 수 | ENI당 IP | 최대 Pod |
|---------------|--------|----------|----------|
| t3.medium | 3 | 6 | 17 |
| t3.large | 3 | 12 | 35 |
| t3.xlarge | 4 | 15 | 58 |
| t3.2xlarge | 4 | 15 | 58 |

### Prefix Delegation 모드 (대형 서브넷용)

> **주의**: /20 이상의 대형 서브넷에서만 권장

Prefix Delegation을 활성화하려면:

```hcl
# EKS Add-on 설정 수정 필요
configuration_values = jsonencode({
  env = {
    ENABLE_PREFIX_DELEGATION = "true"
    WARM_PREFIX_TARGET       = "1"
  }
})
```

| 항목 | 값 |
|------|-----|
| Pod IP 할당 방식 | /28 prefix (16 IP) 단위 할당 |
| 노드당 최대 Pod 수 | 110개 |
| 서브넷 권장 크기 | /20 이상 (4,096 IP) |

---

## 🛡️ Security Group 규칙

| Source | Destination | Port | 설명 |
|--------|-------------|------|------|
| Node SG | Cluster SG | 443 | Worker → API Server |
| Cluster SG | Node SG | 1025-65535 | Control Plane → Worker |
| Node SG | Node SG | All | Worker 간 통신 |
| Mgmt SG | Cluster SG | 443 | Mgmt → API Server |

---

## 🚀 사용 방법

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name    = "petclinic-kr-eks"
  cluster_version = "1.33"
  vpc_id          = module.network.vpc_id

  control_plane_subnet_ids = concat(
    module.network.public_subnet_id,
    module.network.private_eks_subnet_id
  )
  worker_subnet_ids = module.network.private_eks_subnet_id

  node_group_name = "petclinic-kr-workers"
  instance_types  = ["t3.medium"]
  desired_size    = 3
  max_size        = 6
  min_size        = 3

  enable_mgmt_sg_rule    = true
  mgmt_security_group_id = module.ec2.mgmt_security_group_id

}
```

### VPC CNI 버전 지정

```hcl
module "eks" {
  source = "./modules/eks"
  # ... 기타 설정 ...

  vpc_cni_version = "v1.19.2-eksbuild.5"  # 선택사항, 기본값 있음
}
```

---

## 📤 출력값

| 이름 | 설명 |
|------|------|
| `cluster_id` | 클러스터 이름 |
| `cluster_endpoint` | API 서버 엔드포인트 |
| `cluster_certificate_authority_data` | CA 인증서 (Base64) |
| `node_iam_role_arn` | 노드 IAM Role ARN |
| `node_security_group_id` | 노드 SG ID |

---

## 🔐 IAM 정책

### Cluster Role

- AmazonEKSClusterPolicy
- AmazonEKSVPCResourceController

### Node Role

- AmazonEKSWorkerNodePolicy
- AmazonEKS_CNI_Policy
- AmazonEC2ContainerRegistryReadOnly
- AmazonSSMManagedInstanceCore
