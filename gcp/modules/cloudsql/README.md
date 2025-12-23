# Cloud SQL Module

Cloud SQL MySQL 인스턴스를 생성합니다.

## 📋 생성되는 리소스

| 리소스 | 수량 | 설명 |
|--------|------|------|
| Cloud SQL Instance | 1 | MySQL 8.0 |
| Database | 1 | petclinic |
| User | 1 | 애플리케이션용 |
| Private IP Range | 1 | VPC Peering용 |
| VPC Peering | 1 | Private Service Connection |
| Secret Manager | 1 | DB 자격 증명 저장 |

---

## 🏗️ 아키텍처

```
┌─────────────────┐     VPC Peering      ┌─────────────────────┐
│  petclinic-dr   │ ◄──────────────────► │  Google Managed     │
│     VPC         │  servicenetworking-  │  Service Network    │
│  172.16.0.0/16  │  googleapis-com      │  (Cloud SQL 위치)   │
└─────────────────┘                      └─────────────────────┘
```

---

## 🔐 Private Access

- **Private IP Only**: 외부 IP 없음
- **VPC Peering**: Service Networking Connection
- **VPC 내부 접근만 허용**

---

## 🔑 Secret Manager 연동

DB 자격 증명이 Secret Manager에 자동 저장됩니다.

```json
{
  "SPRING_DATASOURCE_URL": "jdbc:mysql://10.x.x.x:3306/petclinic",
  "SPRING_DATASOURCE_USERNAME": "petclinic",
  "SPRING_DATASOURCE_PASSWORD": "****",
  "MYSQL_HOST": "10.x.x.x",
  "MYSQL_PORT": "3306",
  "MYSQL_DATABASE": "petclinic"
}
```

---

## 🚀 사용 방법

```hcl
module "cloudsql" {
  source = "../modules/cloudsql"

  project_id    = "my-project"
  project_name  = "petclinic-dr"
  region        = "asia-northeast3"
  environment   = "dr"

  network_id        = module.network.vpc_id
  tier              = "db-f1-micro"
  database_name     = "petclinic"
  database_user     = "petclinic"
  database_password = var.db_password

  external_secrets_sa_email = module.gke.external_secrets_sa_email
}
```

---

## 📤 출력값

| 이름 | 설명 |
|------|------|
| `instance_name` | Cloud SQL 인스턴스 이름 |
| `private_ip` | Private IP 주소 |
| `connection_name` | 연결 이름 (project:region:instance) |
| `database_name` | 데이터베이스 이름 |
| `secret_id` | Secret Manager Secret ID |

---

## ⚠️ Destroy 시 주의사항

Cloud SQL 삭제 시 **VPC Peering이 먼저 해제되어야** VPC 삭제가 가능합니다.

```bash
# 수동 삭제 순서
1. Cloud SQL 인스턴스 삭제
2. Service Networking Connection 삭제
3. VPC Peering 삭제
4. Global Address 삭제
```

GitHub Actions의 `terraform-destroy.yml`에서 Pre-Cleanup으로 자동 처리됩니다.

---

## 📚 참고 자료

- [Cloud SQL](https://cloud.google.com/sql/docs)
- [Private Service Connection](https://cloud.google.com/vpc/docs/private-services-access)
