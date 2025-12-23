# GCP Network Module

VPC, Subnet, Cloud NAT, Firewall을 생성합니다.

## 📋 생성되는 리소스

| 리소스 | 수량 | 설명 |
|--------|------|------|
| VPC | 1 | 172.16.0.0/16 |
| Subnet | 3 | Public, Private, GKE |
| Cloud Router | 1 | Cloud NAT용 |
| Cloud NAT | 1 | Private 인스턴스 인터넷 접근 |
| Firewall Rules | 3 | Internal, IAP SSH, Health Check |
| Route | 1 | Default Internet Route |

---

## 🌐 서브넷 구성

| 종류 | CIDR | 용도 |
|------|------|------|
| Public | 172.16.10.0/24 | Bastion Host |
| Private | 172.16.50.0/24 | Management Server |
| GKE | 172.16.100.0/24 | GKE Node |

### GKE Secondary Ranges

| 이름 | CIDR | 용도 |
|------|------|------|
| pods | /20 | Pod IP |
| services | /24 | Service IP |

---

## 🔥 Firewall Rules

| 이름 | 소스 | 대상 | 포트 | 설명 |
|------|------|------|------|------|
| allow-internal | VPC CIDR | All | All | VPC 내부 통신 |
| allow-iap-ssh | 35.235.240.0/20 | All | 22 | IAP SSH 접근 |
| allow-health-check | GCP LB IP | All | TCP | Health Check |

---

## 🚀 사용 방법

```hcl
module "network" {
  source = "../modules/network"

  project_id   = "my-project"
  project_name = "petclinic-dr"
  region       = "asia-northeast3"
  vpc_cidr     = "172.16.0.0/16"
}
```

---

## 📤 출력값

| 이름 | 설명 |
|------|------|
| `vpc_id` | VPC ID |
| `vpc_name` | VPC 이름 |
| `public_subnet_id` | Public Subnet ID |
| `private_subnet_id` | Private Subnet ID |
| `gke_subnet_id` | GKE Subnet ID |
| `pods_secondary_range_name` | Pod Secondary Range 이름 |
| `services_secondary_range_name` | Service Secondary Range 이름 |

---

## 🔀 라우팅 구조

```
Public Subnet → Internet Gateway → 인터넷
Private/GKE Subnet → Cloud NAT → Cloud Router → 인터넷
```

---

## 📚 참고 자료

- [GCP VPC](https://cloud.google.com/vpc/docs)
- [Cloud NAT](https://cloud.google.com/nat/docs)
