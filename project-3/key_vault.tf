# ==============================================================================
# 1. CONTEXT & UNIQUE NAMING
# ==============================================================================

# Fetches current authenticated Azure tenant and client ID
data "azurerm_client_config" "current" {}

# Generates 6 random lowercase characters so Key Vault name is globally unique
resource "random_string" "kv_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ==============================================================================
# 2. AZURE KEY VAULT RESOURCE
# ==============================================================================
resource "azurerm_key_vault" "kv" {
  name                       = "kv-3tier-${random_string.kv_suffix.result}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = var.common_tags

  # Access Policy: Grants our deploying identity permission to manage secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover"
    ]
  }

  # Network ACL: Restricts access to Microsoft backbone & App Subnet
  network_acls {
    default_action             = "Allow"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.app.id]
  }
}

# ==============================================================================
# 3. SECRETS: DATABASE PASSWORD
# ==============================================================================

# Generates strong 16-character DB password (never hardcoded in git!)
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Stores DB password inside Key Vault
resource "azurerm_key_vault_secret" "db_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.db_password.result
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault.kv]
}

# ==============================================================================
# 4. SECRETS: 4096-BIT RSA SSH KEY PAIR
# ==============================================================================

# Generates cryptographic RSA SSH Key pair
resource "tls_private_key" "vmss_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Stores private key in Key Vault for zero-leak SSH access
resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "vmss-ssh-private-key"
  value        = tls_private_key.vmss_ssh.private_key_pem
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault.kv]
}
