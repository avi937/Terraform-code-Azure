# 1. Resource Group (The organizational & lifecycle boundary)
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.common_tags
}

# 2. Virtual Network (The isolated private network spanning the region)
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space
  tags                = var.common_tags
}

# 3. Tier 1: Public Web Subnet (For Load Balancers & Web Servers)
resource "azurerm_subnet" "web" {
  name                 = "snet-web-${var.environment}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.web_subnet_cidr
}

# 4. Tier 2: Private Application Subnet (For Backend APIs & Microservices)
resource "azurerm_subnet" "app" {
  name                 = "snet-app-${var.environment}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.app_subnet_cidr
}

# 5. Tier 3: Private Database Subnet (For Azure SQL / Database tier)
resource "azurerm_subnet" "db" {
  name                 = "snet-db-${var.environment}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.db_subnet_cidr
}
