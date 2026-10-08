# ==============================================================================
# 1. WEB TIER NSG (Public-facing firewall)
# ==============================================================================
resource "azurerm_network_security_group" "web_nsg" {
  name                = "nsg-web-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.common_tags

  # Priority 100: Allow HTTP inbound from public internet
  security_rule {
    name                       = "Allow-HTTP-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Priority 110: Allow HTTPS inbound from public internet
  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# Attach Web NSG to Web Subnet
resource "azurerm_subnet_network_security_group_association" "web_assoc" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

# ==============================================================================
# 2. APP TIER NSG (Private backend firewall - Only accepts traffic from Web tier)
# ==============================================================================
resource "azurerm_network_security_group" "app_nsg" {
  name                = "nsg-app-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.common_tags

  # Priority 100: Only Web subnet can talk to App port 8080
  security_rule {
    name                       = "Allow-Web-To-App-8080"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.web_subnet_cidr[0]
    destination_address_prefix = "*"
  }

  # Priority 1000: Explicitly block all other inbound traffic
  security_rule {
    name                       = "Deny-All-Other-Inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Attach App NSG to App Subnet
resource "azurerm_subnet_network_security_group_association" "app_assoc" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# ==============================================================================
# 3. DATABASE TIER NSG (Super-private firewall - Only accepts traffic from App tier)
# ==============================================================================
resource "azurerm_network_security_group" "db_nsg" {
  name                = "nsg-db-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.common_tags

  # Priority 100: Only App subnet can talk to Database port 1433
  security_rule {
    name                       = "Allow-App-To-DB-1433"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = var.app_subnet_cidr[0]
    destination_address_prefix = "*"
  }

  # Priority 1000: Explicitly block all other inbound traffic (including Web!)
  security_rule {
    name                       = "Deny-All-Other-Inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Attach DB NSG to DB Subnet
resource "azurerm_subnet_network_security_group_association" "db_assoc" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}
