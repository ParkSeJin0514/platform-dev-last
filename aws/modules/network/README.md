# Network Module

VPC와 관련된 모든 네트워크 리소스를 생성합니다.

## 📋 생성되는 리소스

| 리소스 | 수량 | 설명 |
|--------|------|------|
| VPC | 1 | 10.0.0.0/16 |
| Internet Gateway | 1 | Public Subnet 인터넷 연결 |
| Subnet | 8 | 4종류 × 2 AZ |
| NAT Gateway | 1 | Regional (단일, 모든 AZ 자동 커버) |
| Route Table | 2 | Public 1개 + Private 1개 |

---

## 🌐 Regional NAT Gateway

AWS Provider >= 6.24.0부터 지원되는 **Regional NAT Gateway**를 사용합니다.

### 기존 방식 (Zonal) vs 현재 방식 (Regional)

| 항목 | Zonal (기존) | Regional (현재) |
|------|-------------|-----------------|
| NAT Gateway 개수 | AZ당 1개 | **1개** |
| Elastic IP | AZ당 1개 | 자동 관리 (Auto Mode) |
| Route Table | AZ별 Private RT | **단일 Private RT** |
| 비용 | NAT Gateway × AZ 개수 | **NAT Gateway 1개** |
| 고가용성 | 수동 구성 | **AWS 자동 관리** |

---

## 🌐 서브넷 구성

| 종류 | AZ-a | AZ-b | 용도 |
|------|------|------|------|
| Public (Bastion) | 10.0.10.0/24 | 10.0.20.0/24 | Bastion, NAT, ALB |
| Private Mgmt | 10.0.50.0/24 | 10.0.60.0/24 | Management Instance |
| Private EKS | 10.0.100.0/24 | 10.0.110.0/24 | EKS Worker Nodes |
| Private DB | 10.0.150.0/24 | 10.0.160.0/24 | RDS 등 |

---

## 🏷️ Kubernetes 태그

ALB Controller가 서브넷을 자동 인식하기 위한 태그가 적용됩니다.

| 서브넷 | 태그 |
|--------|------|
| Public (Bastion) | `kubernetes.io/role/elb = 1` |
| Private EKS | `kubernetes.io/role/internal-elb = 1` |

---

## 🚀 사용 방법

```hcl
module "network" {
  source = "./modules/network"

  vpc_cidr     = "10.0.0.0/16"
  az_count     = 2
  project_name = "petclinic-kr"
}
```

---

## 📤 출력값

| 이름 | 설명 |
|------|------|
| `vpc_id` | VPC ID |
| `vpc_cidr` | VPC CIDR |
| `public_subnet_ids` | Public Subnet ID 리스트 |
| `private_mgmt_subnet_ids` | Mgmt Subnet ID 리스트 |
| `private_eks_subnet_ids` | EKS Subnet ID 리스트 |
| `private_db_subnet_ids` | DB Subnet ID 리스트 |
| `nat_gateway_id` | Regional NAT Gateway ID |

---

## 🔀 라우팅 구조

```
Public Subnet → Internet Gateway → 인터넷
Private Subnet → Regional NAT Gateway → Internet Gateway → 인터넷
```

---

## 📚 참고 자료

- [AWS Regional NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [Terraform AWS Provider 6.24.0](https://registry.terraform.io/providers/hashicorp/aws/6.24.0)
