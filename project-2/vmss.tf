# 1. Generate secure 4096-bit RSA SSH Key Pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Save private key locally for SSH access (Excluded from git by .gitignore)
resource "local_file" "ssh_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/id_rsa.pem"
  file_permission = "0600"
}

# 3. Cloud-Init script to auto-install NGINX and custom landing page
locals {
  cloud_init = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx

    # Create dynamic HTML page displaying the VM's hostname and IP
    HOSTNAME=$(hostname)
    IP=$(hostname -I | cut -d' ' -f1)

    cat <<HTML > /var/www/html/index.html
    <!DOCTYPE html>
    <html>
    <head>
      <title>Project 2: Azure HA VMSS</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #f8fafc; text-align: center; padding: 50px; }
        .card { background: #1e293b; border-radius: 12px; padding: 40px; max-width: 600px; margin: 0 auto; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #334155; }
        h1 { color: #38bdf8; margin-bottom: 8px; }
        .badge { background: #10b981; color: white; padding: 6px 14px; border-radius: 20px; font-size: 14px; font-weight: bold; display: inline-block; margin-bottom: 20px; }
        .info { background: #0f172a; border-radius: 8px; padding: 15px; margin: 15px 0; text-align: left; font-family: monospace; font-size: 15px; }
        .info p { margin: 6px 0; }
        .highlight { color: #f59e0b; font-weight: bold; }
      </style>
    </head>
    <body>
      <div class="card">
        <span class="badge">LIVE HEALTHY INSTANCE</span>
        <h1>Project 2: High Availability VMSS</h1>
        <p>Traffic is being distributed across the fleet by Azure Standard Load Balancer.</p>
        <div class="info">
          <p><strong>Serving Hostname:</strong> <span class="highlight">$HOSTNAME</span></p>
          <p><strong>Private IP Address:</strong> <span class="highlight">$IP</span></p>
          <p><strong>Placement Subnet:</strong> snet-web-dev (10.0.1.0/24)</p>
        </div>
      </div>
    </body>
    </html>
HTML

    systemctl restart nginx
    systemctl enable nginx
  EOF
}

# 4. Linux Virtual Machine Scale Set (VMSS)
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmss-${var.project_name}-${var.environment}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = var.vm_sku
  instances           = var.instance_count
  zones               = ["1"]
  admin_username      = var.admin_username

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
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
      name                                   = "internal"
      primary                                = true
      subnet_id                              = data.terraform_remote_state.network.outputs.web_subnet_id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bepool.id]
    }
  }

  custom_data     = base64encode(local.cloud_init)
  health_probe_id = azurerm_lb_probe.http_probe.id

  depends_on = [azurerm_lb_rule.http_rule]

  tags = var.common_tags
}
