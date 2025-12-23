# VM Module

Bastion Host와 Management 서버를 생성합니다.

## 📋 생성되는 리소스

| 리소스 | 수량 | 설명 |
|--------|------|------|
| Compute Instance | 2 | Bastion, Mgmt |
| Firewall Rules | 2 | Bastion SSH, Internal SSH |

---

## 🔐 접근 흐름

```
인터넷 → Bastion (Public) → Mgmt (Private) → GKE API
```

---

## 🛡️ Firewall Rules

| 이름 | 소스 | 대상 | 포트 | 설명 |
|------|------|------|------|------|
| bastion-ssh | 0.0.0.0/0 | bastion | 22 | SSH 접근 |
| internal-ssh | bastion tag | mgmt, internal | 22 | Bastion → Mgmt |

---

## ⚙️ Management 서버 자동 설정

Startup script가 부팅 시 자동 실행됩니다.

1. **kubectl 설치**: GKE 클러스터 관리
2. **gke-gcloud-auth-plugin**: GKE 인증 플러그인
3. **Docker 설치**: 컨테이너 빌드/실행
4. **mysql-client**: Cloud SQL 접속
5. **GKE 자동 인증**: 클러스터 RUNNING 대기 후 kubeconfig 설정
6. **환경변수 설정**: KUBECONFIG, USE_GKE_GCLOUD_AUTH_PLUGIN

---

## 🖥️ SSH 접속

```bash
# SSH Config (~/.ssh/config)
Host gcp-bastion
  HostName <BASTION_PUBLIC_IP>
  User ubuntu
  IdentityFile ~/.ssh/gcp_key

Host gcp-mgmt
  HostName <MGMT_PRIVATE_IP>
  User ubuntu
  IdentityFile ~/.ssh/gcp_key
  ProxyJump gcp-bastion

# 접속
ssh gcp-bastion
ssh gcp-mgmt
```

---

## 🚀 사용 방법

```hcl
module "vm" {
  source = "../modules/vm"

  project_id   = "my-project"
  project_name = "petclinic-dr"
  region       = "asia-northeast3"
  zone         = "asia-northeast3-a"
  environment  = "dr"

  network_id        = module.network.vpc_id
  public_subnet_id  = module.network.public_subnet_id
  private_subnet_id = module.network.private_subnet_id

  bastion_machine_type = "e2-micro"
  mgmt_machine_type    = "e2-small"

  ssh_user       = "ubuntu"
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  # GKE 설정 (Mgmt 서버 자동 kubectl 설정용)
  gke_cluster_name   = module.gke.cluster_name
  gke_cluster_region = module.gke.cluster_location

  service_account_email = module.gke.node_service_account_email
}
```

---

## 📤 출력값

| 이름 | 설명 |
|------|------|
| `bastion_public_ip` | Bastion Public IP |
| `bastion_private_ip` | Bastion Private IP |
| `mgmt_private_ip` | Mgmt Private IP |

---

## 📝 로그 확인

```bash
# Mgmt 서버에서 startup script 로그 확인
sudo cat /var/log/startup-script.log

# kubectl 수동 설정 (필요시)
./configure-kubectl.sh
```

---

## 📚 참고 자료

- [Compute Engine](https://cloud.google.com/compute/docs)
- [IAP SSH](https://cloud.google.com/iap/docs/using-tcp-forwarding)
