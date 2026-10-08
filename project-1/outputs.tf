# ==============================================================================
# RESOURCE GROUP OUTPUTS
# ==============================================================================
output "resource_group_name" {
  description = "The name of the provisioned Azure Resource Group"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_id" {
  description = "The Resource ID of the Azure Resource Group"
  value       = azurerm_resource_group.rg.id
}

# ==============================================================================
# VIRTUAL NETWORK OUTPUTS
# ==============================================================================
output "virtual_network_name" {
  description = "The name of the Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "virtual_network_id" {
  description = "The Resource ID of the Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "virtual_network_address_space" {
  description = "The address space CIDR block of the Virtual Network"
  value       = azurerm_virtual_network.vnet.address_space
}

# ==============================================================================
# SUBNET ID OUTPUTS (Used by future projects to deploy VMs, DBs, and Load Balancers)
# ==============================================================================
output "web_subnet_id" {
  description = "The Resource ID of the Public Web Subnet"
  value       = azurerm_subnet.web.id
}

output "app_subnet_id" {
  description = "The Resource ID of the Private App Subnet"
  value       = azurerm_subnet.app.id
}

output "db_subnet_id" {
  description = "The Resource ID of the Private DB Subnet"
  value       = azurerm_subnet.db.id
}

# ==============================================================================
# NETWORK SECURITY GROUP OUTPUTS
# ==============================================================================
output "web_nsg_id" {
  description = "The Resource ID of the Web NSG"
  value       = azurerm_network_security_group.web_nsg.id
}

output "app_nsg_id" {
  description = "The Resource ID of the App NSG"
  value       = azurerm_network_security_group.app_nsg.id
}

output "db_nsg_id" {
  description = "The Resource ID of the DB NSG"
  value       = azurerm_network_security_group.db_nsg.id
}
