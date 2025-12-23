# GKE Module

GKE Standard Cluster와 Node Pool을 생성합니다.

## 📋 생성되는 리소스

| 리소스 | 수량 | 설명 |
|--------|------|------|
| GKE Cluster | 1 | Standard Mode |
| Node Pool | 1 | Autoscaling 지원 |
| Service Account | 2 | Node SA, External Secrets SA |
| IAM Binding | 4+ | Node 권한, Workload Identity |

---

## ✨ 주요 기능

- **GKE Standard Mode**: Node Pool 직접 관리
- **Workload Identity**: GCP 서비스 연동
- **VPC-native**: Pod/Service Secondary Range 사용
- **Autoscaling**: Node Pool 자동 확장/축소
- **Auto Repair/Upgrade**: 노드 자동 복구 및 업그레이드

---

## 🔐 Node Service Account 권한

| 역할 | 설명 |
|------|------|
| `roles/logging.logWriter` | Cloud Logging 쓰기 |
| `roles/monitoring.metricWriter` | Cloud Monitoring 메트릭 |
| `roles/stackdriver.resourceMetadata.writer` | Stackdriver 메타데이터 |
| `roles/artifactregistry.reader` | Artifact Registry 이미지 Pull |

---

## 🔗 Workload Identity

External Secrets Operator를 위한 Workload Identity가 자동 설정됩니다.

```yaml
# K8s ServiceAccount annotation
iam.gke.io/gcp-service-account: "external-secrets-sa@project.iam.gserviceaccount.com"
```

---

## 🚀 사용 방법

```hcl
module "gke" {
  source = "../modules/gke"

  project_id   = "my-project"
  project_name = "petclinic-dr"
  region       = "asia-northeast3"

  cluster_name           = "petclinic-dr-gke"
  network_id             = module.network.vpc_id
  subnetwork_id          = module.network.gke_subnet_id
  pods_range_name        = module.network.pods_secondary_range_name
  services_range_name    = module.network.services_secondary_range_name
  master_authorized_cidr = "0.0.0.0/0"
  release_channel        = "REGULAR"

  # Node Pool
  node_machine_type = "e2-standard-4"
  node_count        = 1
  min_node_count    = 1
  max_node_count    = 2

  # Workload Identity
  external_secrets_sa_name = "petclinic-dr-external-secrets"
}
```

---

## 📤 출력값

| 이름 | 설명 |
|------|------|
| `cluster_name` | GKE 클러스터 이름 |
| `cluster_endpoint` | API Server 엔드포인트 |
| `cluster_ca_certificate` | CA 인증서 (Base64) |
| `cluster_location` | 클러스터 리전 |
| `node_service_account_email` | 노드 SA 이메일 |
| `external_secrets_sa_email` | External Secrets SA 이메일 |

---

## 📚 참고 자료

- [GKE Standard](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity)
