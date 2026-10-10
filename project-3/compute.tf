# ==============================================================================
# 1. PUBLIC IP & AZURE LOAD BALANCER (TIER 1 INGRESS)
# ==============================================================================

# Standard Public IP for the Public Load Balancer
resource "azurerm_public_ip" "lb_pip" {
  name                = "pip-lb-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
}

# Azure Public Load Balancer
resource "azurerm_lb" "lb" {
  name                = "lb-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = var.common_tags

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontend"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

# Backend Address Pool (Where the VMSS instances register)
resource "azurerm_lb_backend_address_pool" "bepool" {
  name            = "bepool-${var.project_name}-${var.environment}"
  loadbalancer_id = azurerm_lb.lb.id
}

# Health Probe: Tests HTTP Port 80 every 5s; removes unhealthy VMs
resource "azurerm_lb_probe" "hp" {
  name            = "hp-http-80"
  loadbalancer_id = azurerm_lb.lb.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

# Load Balancing Rule: Forwards Port 80 traffic to the backend VMSS pool
resource "azurerm_lb_rule" "lb_rule" {
  name                           = "rule-http-80"
  loadbalancer_id                = azurerm_lb.lb.id
  frontend_ip_configuration_name = "LoadBalancerFrontend"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bepool.id]
  probe_id                       = azurerm_lb_probe.hp.id
}

# ==============================================================================
# 2. MANAGED IDENTITY & KEY VAULT RBAC (TIER 2 SECURITY)
# ==============================================================================

# User-Assigned Managed Identity for the VMSS
resource "azurerm_user_assigned_identity" "vmss_identity" {
  name                = "id-vmss-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.common_tags
}

# Grants the Managed Identity permission to read secrets from Key Vault
resource "azurerm_key_vault_access_policy" "vmss_kv_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.vmss_identity.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# ==============================================================================
# 3. CLOUD-INIT USER DATA (BOOTSTRAP NGINX & METADATA DASHBOARD)
# ==============================================================================
locals {
  cloud_init = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx

    # Dynamic variables
    HOSTNAME=$(hostname)
    IP=$(hostname -I | cut -d' ' -f1)

    # Render modern production status page
    cat <<HTML > /var/www/html/index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>Project 3: Enterprise 3-Tier Azure Architecture</title>
      <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #0b1120; color: #f8fafc; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; }
        .card { background: #1e293b; padding: 40px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); max-width: 650px; width: 100%; border: 1px solid #334155; }
        h1 { color: #38bdf8; margin-top: 0; font-size: 24px; }
        .badge { display: inline-block; padding: 6px 14px; background: #0284c7; color: white; border-radius: 9999px; font-weight: bold; font-size: 13px; margin-bottom: 20px; }
        .tier { background: #0f172a; padding: 15px; border-radius: 8px; margin-bottom: 12px; border-left: 4px solid #38bdf8; }
        .tier h3 { margin: 0 0 6px 0; font-size: 15px; color: #94a3b8; }
        .tier p { margin: 0; font-family: monospace; font-size: 15px; color: #4ade80; font-weight: bold; }
        .footer { margin-top: 25px; font-size: 13px; color: #64748b; text-align: center; }
      </style>
    </head>
    <body>
      <div class="card">
        <span class="badge">Azure Multi-Tier Architecture Online</span>
        <h1>Project 3: Enterprise 3-Tier Production Stack</h1>
        
        <div class="tier">
          <h3>Tier 1: Ingress Layer (Public Load Balancer)</h3>
          <p>Healthy | Port 80 Forwarding Enabled</p>
        </div>

        <div class="tier">
          <h3>Tier 2: Private Compute (VMSS Instance)</h3>
          <p>Host: $HOSTNAME ($IP) | Subnet: 10.0.2.0/24</p>
        </div>

        <div class="tier">
          <h3>Tier 3: Database & Security Plane</h3>
          <p>Azure SQL DB (${azurerm_mssql_server.sql.name}) | Key Vault Linked</p>
        </div>

        <div class="footer">
          Deployed with Terraform & Azure Resource Manager | Architect: Avi Arora
        </div>
      </div>
    </body>
    </html>
    HTML

    systemctl restart nginx
  EOF
}

# ==============================================================================
# 4. LINUX VIRTUAL MACHINE SCALE SET (TIER 2 PRIVATE COMPUTE)
# ==============================================================================
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmss-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.vm_sku
  instances           = var.instance_count
  admin_username      = var.admin_username
  tags                = var.common_tags

  # Zero hardcoded passwords - Enforces RSA SSH Key authentication
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.vmss_ssh.public_key_openssh
  }

  # Injects cloud-init script
  custom_data = base64encode(local.cloud_init)

  # Attaches Managed Identity to all instances
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vmss_identity.id]
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic-${var.project_name}-${var.environment}"
    primary = true

    ip_configuration {
      name                                   = "ipconfig-internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.app.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bepool.id]
    }
  }

  depends_on = [
    azurerm_lb_rule.lb_rule,
    azurerm_key_vault_access_policy.vmss_kv_policy
  ]
}
