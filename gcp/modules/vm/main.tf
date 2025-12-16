# ============================================================================
# VM Module - main.tf (GCP Compute Engine)
# ============================================================================
# Bastion 및 Management 서버 생성
# ============================================================================

# ============================================================================
# SSH Key Metadata
# ============================================================================
locals {
  ssh_keys = "${var.ssh_user}:${var.ssh_public_key}"
}

# ============================================================================
# Bastion Host (Public Subnet)
# ============================================================================
resource "google_compute_instance" "bastion" {
  name         = "${var.project_name}-bastion"
  machine_type = var.bastion_machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["bastion", "ssh"]

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.public_subnet_id

    # Public IP
    access_config {
      network_tier = "STANDARD"
    }
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y kubectl google-cloud-sdk-gke-gcloud-auth-plugin
  EOF

  labels = {
    environment = var.environment
    role        = "bastion"
    project     = var.project_name
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
}

# ============================================================================
# Management Server (Private Subnet)
# ============================================================================
resource "google_compute_instance" "mgmt" {
  name         = "${var.project_name}-mgmt"
  machine_type = var.mgmt_machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["mgmt", "internal"]

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.private_subnet_id

    # No public IP (private only)
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y kubectl google-cloud-sdk-gke-gcloud-auth-plugin docker.io
    usermod -aG docker ${var.ssh_user}
  EOF

  labels = {
    environment = var.environment
    role        = "management"
    project     = var.project_name
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
}

# ============================================================================
# Firewall Rules
# ============================================================================

# SSH to Bastion from anywhere
resource "google_compute_firewall" "bastion_ssh" {
  name    = "${var.project_name}-bastion-ssh"
  network = var.network_id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion"]
}

# SSH from Bastion to internal servers
resource "google_compute_firewall" "internal_ssh" {
  name    = "${var.project_name}-internal-ssh"
  network = var.network_id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["bastion"]
  target_tags = ["mgmt", "internal"]
}
