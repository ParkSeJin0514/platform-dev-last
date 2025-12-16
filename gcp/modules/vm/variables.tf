# ============================================================================
# VM Module - variables.tf
# ============================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dr"
}

variable "network_id" {
  description = "VPC network ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for Bastion"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for Management server"
  type        = string
}

variable "bastion_machine_type" {
  description = "Machine type for Bastion"
  type        = string
  default     = "e2-micro"
}

variable "mgmt_machine_type" {
  description = "Machine type for Management server"
  type        = string
  default     = "e2-small"
}

variable "image" {
  description = "Boot disk image"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for instances"
  type        = string
}
