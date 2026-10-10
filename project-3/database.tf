# ==============================================================================
# 1. AZURE SQL LOGICAL SERVER
# ==============================================================================
resource "azurerm_mssql_server" "sql" {
  name                         = "sql-${var.project_name}-${random_string.kv_suffix.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = azurerm_key_vault_secret.db_admin_password.value
  minimum_tls_version          = "1.2"
  tags                         = var.common_tags
}

# ==============================================================================
# 2. AZURE SQL DATABASE (Basic Tier - Pennies to run, 100% Free Trial Friendly)
# ==============================================================================
resource "azurerm_mssql_database" "db" {
  name         = "db-enterprise-app"
  server_id    = azurerm_mssql_server.sql.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "Basic"
  tags         = var.common_tags
}

# ==============================================================================
# 3. VIRTUAL NETWORK FIREWALL RULE (ZERO-TRUST SECURITY)
# ==============================================================================

# Locks the SQL Server so ONLY instances inside App Subnet can connect on Port 1433
resource "azurerm_mssql_virtual_network_rule" "sql_vnet_rule" {
  name      = "sql-vnet-rule-app"
  server_id = azurerm_mssql_server.sql.id
  subnet_id = azurerm_subnet.app.id
}
