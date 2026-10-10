# ==============================================================================
# TIER 1: LOAD BALANCER & PUBLIC ACCESS
# ==============================================================================
output "load_balancer_public_ip" {
  description = "The Public IPv4 address assigned to the Azure Load Balancer"
  value       = azurerm_public_ip.lb_pip.ip_address
}

output "application_url" {
  description = "Direct HTTP URL to access the 3-Tier Web Application"
  value       = "http://${azurerm_public_ip.lb_pip.ip_address}"
}

# ==============================================================================
# TIER 2: COMPUTE & IDENTITY
# ==============================================================================
output "vmss_name" {
  description = "The name of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.name
}

output "managed_identity_principal_id" {
  description = "Principal ID of the Managed Identity used for Key Vault RBAC"
  value       = azurerm_user_assigned_identity.vmss_identity.principal_id
}

# ==============================================================================
# TIER 3: DATABASE & SECRETS
# ==============================================================================
output "key_vault_name" {
  description = "The globally unique name of the Azure Key Vault safe"
  value       = azurerm_key_vault.kv.name
}

output "sql_server_fqdn" {
  description = "Fully Qualified Domain Name of the Azure SQL Logical Server"
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "The name of the Azure SQL Database"
  value       = azurerm_mssql_database.db.name
}

output "ssh_private_key_secret_name" {
  description = "The secret name in Key Vault holding the VMSS RSA SSH Private Key"
  value       = azurerm_key_vault_secret.ssh_private_key.name
}
