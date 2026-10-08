output "load_balancer_public_ip" {
  description = "The public IP address of the Azure Load Balancer"
  value       = azurerm_public_ip.lb_pip.ip_address
}

output "load_balancer_url" {
  description = "Web URL to access the live load-balanced application"
  value       = "http://${azurerm_public_ip.lb_pip.ip_address}"
}

output "vmss_id" {
  description = "The Resource ID of the Linux VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.id
}

output "vmss_name" {
  description = "The name of the Linux VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.name
}

output "ssh_private_key_path" {
  description = "Path to the local private SSH key"
  value       = local_file.ssh_key.filename
}
