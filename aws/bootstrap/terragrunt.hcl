# ============================================================================
# Bootstrap Layer (ArgoCD)
# ============================================================================
# 의존성: Foundation, Compute
# ArgoCD 설치 및 Root Application 배포
# ============================================================================

include "root" {
  path = find_in_parent_folders()
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules//bootstrap"
}

# ============================================================================
# 의존성 선언
# ============================================================================
dependency "foundation" {
  config_path = "../foundation"

  mock_outputs = {
    vpc_id       = "vpc-mock"
    project_name = "mock-project"
    region       = "ap-northeast-2"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

dependency "compute" {
  config_path = "../compute"

  mock_outputs = {
    eks_cluster_name                       = "mock-cluster"
    eks_cluster_endpoint                   = "https://mock.eks.amazonaws.com"
    eks_cluster_certificate_authority_data = "bW9jay1jZXJ0"
    eks_node_iam_role_arn                  = "arn:aws:iam::123456789012:role/mock-node"
    mgmt_iam_role_arn                      = "arn:aws:iam::123456789012:role/mock-mgmt"
    alb_controller_role_arn                = "arn:aws:iam::123456789012:role/mock-alb"
    efs_csi_driver_role_arn                = "arn:aws:iam::123456789012:role/mock-efs"
    external_secrets_role_arn              = "arn:aws:iam::123456789012:role/mock-es"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

# ============================================================================
# Provider Override - Bootstrap 전용
# ============================================================================
# Root의 _provider.tf를 override하여 kubernetes/helm/kubectl 추가
# 모든 required_providers를 하나의 terraform 블록에 선언해야 함
# ============================================================================
generate "provider" {
  path      = "_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.0"

      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = ">= 6.24.0"
        }
        tls = {
          source  = "hashicorp/tls"
          version = "~> 4.0"
        }
        time = {
          source  = "hashicorp/time"
          version = "~> 0.9"
        }
        kubernetes = {
          source  = "hashicorp/kubernetes"
          version = "~> 2.23"
        }
        helm = {
          source  = "hashicorp/helm"
          version = "~> 2.11"
        }
        kubectl = {
          source  = "gavinbunney/kubectl"
          version = "~> 1.14"
        }
      }
    }

    provider "aws" {
      region = "ap-northeast-2"

      default_tags {
        tags = {
          Environment = "production"
          Project     = "petclinic-kr"
          ManagedBy   = "Terragrunt"
        }
      }
    }

    data "aws_eks_cluster_auth" "cluster" {
      name = "${dependency.compute.outputs.eks_cluster_name}"
    }

    provider "kubernetes" {
      host                   = "${dependency.compute.outputs.eks_cluster_endpoint}"
      cluster_ca_certificate = base64decode("${dependency.compute.outputs.eks_cluster_certificate_authority_data}")
      token                  = data.aws_eks_cluster_auth.cluster.token
    }

    provider "helm" {
      kubernetes {
        host                   = "${dependency.compute.outputs.eks_cluster_endpoint}"
        cluster_ca_certificate = base64decode("${dependency.compute.outputs.eks_cluster_certificate_authority_data}")
        token                  = data.aws_eks_cluster_auth.cluster.token
      }
    }

    provider "kubectl" {
      host                   = "${dependency.compute.outputs.eks_cluster_endpoint}"
      cluster_ca_certificate = base64decode("${dependency.compute.outputs.eks_cluster_certificate_authority_data}")
      token                  = data.aws_eks_cluster_auth.cluster.token
      load_config_file       = false
    }
  EOF
}

# ============================================================================
# 입력 변수
# ============================================================================
inputs = {
  # Foundation에서 가져온 값
  project_name = dependency.foundation.outputs.project_name
  region       = dependency.foundation.outputs.region
  vpc_id       = dependency.foundation.outputs.vpc_id

  # Compute에서 가져온 값
  cluster_name                       = dependency.compute.outputs.eks_cluster_name
  cluster_endpoint                   = dependency.compute.outputs.eks_cluster_endpoint
  cluster_certificate_authority_data = dependency.compute.outputs.eks_cluster_certificate_authority_data
  node_iam_role_arn                  = dependency.compute.outputs.eks_node_iam_role_arn
  mgmt_iam_role_arn                  = dependency.compute.outputs.mgmt_iam_role_arn

  # IRSA Role ARNs
  alb_controller_role_arn   = dependency.compute.outputs.alb_controller_role_arn
  efs_csi_driver_role_arn   = dependency.compute.outputs.efs_csi_driver_role_arn
  external_secrets_role_arn = dependency.compute.outputs.external_secrets_role_arn

  # ArgoCD 설정
  argocd_chart_version   = local.env.locals.argocd_chart_version
  argocd_namespace       = local.env.locals.argocd_namespace
  gitops_repo_url        = local.env.locals.gitops_repo_url
  gitops_target_revision = local.env.locals.gitops_target_revision
}
