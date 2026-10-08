# Read Resource Group details (name and location) from Project 1
data "azurerm_resource_group" "rg" {
  name = data.terraform_remote_state.network.outputs.resource_group_name
}

# 1. Public IP for the Load Balancer
resource "azurerm_public_ip" "lb_pip" {
  name                = "pip-${var.project_name}-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
}

# 2. Azure Standard Load Balancer
resource "azurerm_lb" "lb" {
  name                = "lb-${var.project_name}-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = var.common_tags

  frontend_ip_configuration {
    name                 = "PublicFrontendIP"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

# 3. Backend Address Pool (Target group for VMSS instances)
resource "azurerm_lb_backend_address_pool" "bepool" {
  name            = "bepool-${var.project_name}-${var.environment}"
  loadbalancer_id = azurerm_lb.lb.id
}

# 4. HTTP Health Probe (Checks port 80 on each VM every 15 seconds)
resource "azurerm_lb_probe" "http_probe" {
  name                = "probe-http-80"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 15
  number_of_probes    = 2
}

# 5. Load Balancing Rule (Routes incoming port 80 traffic to healthy backend VMs)
resource "azurerm_lb_rule" "http_rule" {
  name                           = "rule-http-80"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicFrontendIP"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bepool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
}
