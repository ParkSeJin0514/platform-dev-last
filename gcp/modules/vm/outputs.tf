# ============================================================================
# VM Module - outputs.tf
# ============================================================================

output "bastion_name" {
  description = "Bastion instance name"
  value       = google_compute_instance.bastion.name
}

output "bastion_public_ip" {
  description = "Bastion public IP address"
  value       = google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip
}

output "bastion_private_ip" {
  description = "Bastion private IP address"
  value       = google_compute_instance.bastion.network_interface[0].network_ip
}

output "mgmt_name" {
  description = "Management server instance name"
  value       = google_compute_instance.mgmt.name
}

output "mgmt_private_ip" {
  description = "Management server private IP address"
  value       = google_compute_instance.mgmt.network_interface[0].network_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to Bastion"
  value       = "ssh -i <private-key> ubuntu@${google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip}"
}

output "mgmt_ssh_command" {
  description = "SSH command to connect to Management server via Bastion"
  value       = "ssh -i <private-key> -J ubuntu@${google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip} ubuntu@${google_compute_instance.mgmt.network_interface[0].network_ip}"
}
