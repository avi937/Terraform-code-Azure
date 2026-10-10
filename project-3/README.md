# 🏆 Project 3: Enterprise 3-Tier Production Architecture (Public ALB → Private VMSS → Azure SQL + Key Vault & Managed Identity)

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AzureRM](https://img.shields.io/badge/AzureRM-v4.0+-0089D6?logo=microsoftazure&logoColor=white)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![OS](https://img.shields.io/badge/OS-Ubuntu_24.04_LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Database](https://img.shields.io/badge/Database-Azure_SQL_PaaS-0078D4?logo=microsoftazure&logoColor=white)](#)
[![Security](https://img.shields.io/badge/Security-Key_Vault_+_Managed_Identity-brightgreen)](#)
[![Status](https://img.shields.io/badge/Status-Completed_✅-brightgreen)](#)

A flagship, enterprise-grade **3-Tier Production Cloud Architecture** built on Microsoft Azure completely via Terraform (`azurerm`). Designed with **Zero-Trust network segmentation**, an **Azure Public Load Balancer**, private auto-scaling **Linux Virtual Machine Scale Sets (VMSS)** with **zero public IPs**, an **Azure SQL Database** protected by **Virtual Network Service Endpoints**, and an **Azure Key Vault** integrated with **User-Assigned Managed Identity** for 100% passwordless secret retrieval.

---

## 🏛️ Architecture Blueprint

```
                                  [ 🌐 Users on Public Internet ]
                                                 │
                                                 │ HTTP (Port 80)
                                                 ▼
                        ┌──────────────────────────────────────────────────┐
                        │      Static Azure Public IP (Standard SKU)       │
                        │                (20.207.197.39)                   │
                        └──────────────────────────────────────────────────┘
                                                 │
                                                 ▼
                        ┌──────────────────────────────────────────────────┐
                        │          Azure Public Load Balancer              │
                        │    • Frontend: Public IP Port 80                 │
                        │    • Health Probe: HTTP Port 80 (5s interval)    │
                        │    • Load Balancing Rule: Port 80 -> 80          │
                        └──────────────────────────────────────────────────┘
                                                 │
                                 Backend Address Pool (bepool)
                                                 │
              ┌──────────────────────────────────┴──────────────────────────────────┐
              ▼                                                                     ▼
┌───────────────────────────────┐                                     ┌───────────────────────────────┐
│     VMSS Instance 0           │                                     │     VMSS Instance 1           │
│  • Private IP: 10.0.2.5       │                                     │  • Private IP: 10.0.2.4       │
│  • Subnet: snet-app-dev       │                                     │  • Subnet: snet-app-dev       │
│  • Zero Public IPs            │                                     │  • Zero Public IPs            │
│  • NGINX Web Application      │                                     │  • NGINX Web Application      │
│  • User-Assigned Identity     │                                     │  • User-Assigned Identity     │
└──────────────┬────────────────┘                                     └──────────────┬────────────────┘
               │                                                                     │
               └──────────────────────────────────┬──────────────────────────────────┘
                                                  │
                                                  │ Private VNet Service Endpoints (No Internet Traversal!)
                                                  │
                       ┌──────────────────────────┴──────────────────────────┐
                       ▼                                                     ▼
        ┌───────────────────────────────┐                     ┌───────────────────────────────┐
        │      🔐 Azure Key Vault       │                     │    🗄️ Azure SQL Logical Server│
        │ • Stores DB Admin Password    │                     │ • Server: sql-enterprise-3tier│
        │ • Stores 4096-bit SSH Key     │                     │ • Database: db-enterprise-app │
        │ • Access Policy: Managed ID   │                     │ • VNet Rule: snet-app-dev ONLY│
        └───────────────────────────────┘                     └───────────────────────────────┘
```

---

## 📂 Project Directory Structure

```
project-3/
├── provider.tf        # azurerm v4.0+, random, tls providers with remote backend
├── variables.tf       # Parameterized network CIDRs, VM size, SKUs, and tags
├── terraform.tfvars   # Dev environment concrete values
├── networking.tf      # Resource Group, VNet, 3 Subnets (Web/App/DB), and NSGs
├── key_vault.tf       # Azure Key Vault, Random Password, RSA 4096 SSH Key, Access Policy
├── database.tf        # Azure SQL Logical Server, Database, and VNet Firewall Rule
├── compute.tf         # Public Load Balancer, Probe, Rule, Managed Identity, and VMSS
├── outputs.tf         # Application URL, Load Balancer IP, Key Vault Name, SQL FQDN
└── test-project3.ps1  # Automated 12-test E2E validation script
```

---

## 🛡️ Enterprise 3-Tier Layer Breakdown

### Tier 1: Ingress & Load Balancing
* **Azure Public Load Balancer (Standard SKU)**: Distributes public HTTP traffic across backend instances.
* **Standard Public IP**: Static, dedicated public IP (`allocation_method = "Static"`, `sku = "Standard"`).
* **Health Probe (`azurerm_lb_probe`)**: Pings HTTP Port `80` every 5 seconds with a threshold of 2 probes.
* **Load Balancing Rule (`azurerm_lb_rule`)**: Forwards incoming Port 80 packets to the backend address pool.

### Tier 2: Private Compute (VMSS) & Managed Identity
* **Linux Virtual Machine Scale Set (VMSS)**: Running 2 instances of Ubuntu 24.04 LTS Gen2 (`Standard_B2ats_v2`).
* **Zero Public Attack Surface**: Backend instances have **ZERO public IP addresses**. They live strictly within `10.0.2.0/24`.
* **Zero Hardcoded Passwords**: SSH password authentication is explicitly disabled (`disable_password_authentication = true`). Authentication uses a **4096-bit RSA SSH key pair** generated by Terraform on the fly.
* **User-Assigned Managed Identity**: An Entra ID identity attached to the VMSS, allowing passwordless communication with Azure Key Vault.

### Tier 3: Managed Database (Azure SQL) & Security Plane
* **Azure SQL Logical Server**: Managed PaaS relational server (`sql-enterprise-3tier-xxxx.database.windows.net`) with `minimum_tls_version = "1.2"`.
* **Azure SQL Database**: Dedicated database (`db-enterprise-app`) running on the cost-efficient `Basic` tier (5 DTUs, 2 GB).
* **Virtual Network Firewall Rule (`azurerm_mssql_virtual_network_rule`)**: Locks down Azure SQL so **ONLY traffic originating from `snet-app-dev` (10.0.2.0/24)** can connect on Port 1433. All direct internet traffic is dropped.
* **Azure Key Vault**: Hardware-backed safe storing `sql-admin-password` and `vmss-ssh-private-key`. Configured with `purge_soft_delete_on_destroy = true` for clean resource teardown.

---

# 🧠 Comprehensive Architectural Q&A (Deep-Dive Concepts)

### Q1: Why allocate a dedicated Public IP in Azure instead of AWS ALB's automatic DNS/IPs?
* **In AWS:** An Application Load Balancer does not provide a static public IP; it provisions hidden instances across subnets and returns a long CNAME (`my-alb-123.elb.amazonaws.com`) whose underlying IPs change dynamically.
* **In Azure:** Azure Load Balancer is a software-defined routing fabric baked into Microsoft's datacenter networking. It provides a **dedicated, permanent Static Public IP (`azurerm_public_ip`)** that never changes, allowing immediate mapping of standard DNS `A Records` without CNAME flattening.

### Q2: How do instances join the Load Balancer Backend Address Pool? (The Guest List Analogy)
* **The Analogy:** The `azurerm_lb_backend_address_pool` acts like an empty VIP guest list called `bepool`.
* **Auto-Registration:** Inside the VMSS `network_interface` block, we assign:
  ```hcl
  load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bepool.id]
  ```
* As soon as an instance boots and acquires an internal private IP (`10.0.2.4`), Azure's network virtualization automatically writes that IP onto the guest list. When the scale set scales out (e.g. from 2 to 5 VMs), every new VM automatically registers into the pool with zero human intervention.

### Q3: What happens if multiple containers run on a VM with different ports?
* **Pattern 1 (Enterprise Standard - Reverse Proxy):** Run **NGINX** on the VM listening on port `80`. The Load Balancer probes port 80. NGINX receives the traffic and routes internally (`/users` -> `localhost:3000`, `/payments` -> `localhost:4000`).
* **Pattern 2 (Direct Port Probing):** Configure separate health probes and load balancing rules per port (Frontend 3000 -> Backend 3000, Frontend 4000 -> Backend 4000). If Container 3000 crashes, only that port's probe fails, while port 4000 continues serving traffic.

### Q4: What is a Managed Identity vs a human IAM user?
* **It is NOT a human user with credentials.** Think of it like a **Digital RFID Employee Smart Card** issued by Microsoft Entra ID.
* We assign this smart card to the VMSS (`identity_ids = [azurerm_user_assigned_identity.vmss_identity.id]`).
* On Azure Key Vault, we grant this smart card permission to read secrets (`azurerm_key_vault_access_policy`).
* **Why this is senior-grade:** When the application runs, it requests an OAuth token directly from Azure's internal metadata endpoint (`http://169.254.169.254/metadata/identity/oauth2/token`). **Zero passwords or API tokens ever exist in source code or environment files.**

### Q5: What are `network_interface` and `ip_configuration` in simple terms?
* The `network_interface` is the virtual **Ethernet / Wi-Fi Card** attached to the computer.
* The `ip_configuration` is the **settings page** of that card:
  * Which subnet to join (`subnet_id = azurerm_subnet.app.id`)
  * Which Load Balancer pool to connect to (`load_balancer_backend_address_pool_ids = [...]`)
  * Whether to assign a public IP (No, private internal only).

### Q6: Why Base64-encode the Cloud-Init script (`custom_data`)?
* Cloud provider REST APIs can corrupt raw shell script characters (quotes `"`, dollar signs `$`, line breaks `\n`).
* Base64 converts the entire bash script into a safe, alphanumeric string. When the Ubuntu VM turns on, systemd's `cloud-init` automatically decodes it and runs it cleanly.

### Q7: What are Azure Service Endpoints (`Microsoft.KeyVault`, `Microsoft.Sql`)?
* Normally, Key Vault and Azure SQL are public PaaS endpoints. Without Service Endpoints, VM traffic would traverse outside to the public internet and back in.
* **The Private Tunnel Analogy:** A Service Endpoint creates an internal fiber tunnel across Microsoft's private network backbone. Packets between `snet-app` and Azure SQL / Key Vault **NEVER touch the public internet**, providing lower latency, higher bandwidth, and complete isolation from external eavesdropping.

### Q8: Why are there two separate resources for Azure SQL (`mssql_server` vs `mssql_database`)?
* **The Analogy:** Think of the **Logical Server** as an **Office Building**, and the **Database** as an **Office Room inside the building**.
* `azurerm_mssql_server` manages the endpoint URL (`.database.windows.net`), admin account (`sqladmin`), firewall rules, and encryption.
* `azurerm_mssql_database` manages the actual tables, schemas, storage caps (2 GB), and compute tiers (`Basic`). Multiple databases can live inside one server.

### Q9: What is SQL Collation (`SQL_Latin1_General_CP1_CI_AS`)?
* It defines how SQL Server sorts and compares characters:
  * `Latin1_General`: Standard English character set.
  * `CP1`: Code Page 1.
  * `CI`: **C**ase-**I**nsensitive (`"Avi"` matches `"avi"`).
  * `AS`: **A**ccent-**S**ensitive (`"e"` is distinct from `"é"`).

### Q10: How does Azure handle state locking without DynamoDB?
* In AWS, S3 lacks native write-locking, requiring a separate DynamoDB table with a `LockID` primary key.
* **Azure Blob Storage natively supports Blob Leases.** When Terraform runs `plan` or `apply`, it requests an exclusive 60-second lease lock directly on `project-3/terraform.tfstate`. If another engineer runs apply concurrently, Azure returns a lease conflict error. When done, Terraform releases the lease. No external database is needed!

---

# 🚨 Real-World Troubleshooting Playbook: The Layer 4 vs Layer 7 NSG Drop

During live testing, our web application initially returned **`ERR_CONNECTION_TIMED_OUT`** on `http://20.207.197.39`. Here is the full diagnostic investigation:

```
[Issue]       Chrome and curl timed out when accessing Load Balancer Public IP (20.207.197.39:80).
[Step 1]      Executed Azure CLI diagnostic directly on instance:
              az vmss run-command invoke --name vmss-enterprise-3tier-dev --instance-id 0 --scripts "systemctl status nginx"
[Result 1]    Nginx was active (running) and curl http://localhost returned HTTP 200 OK!
[Step 2]      Analyzed the incoming packet flow from public internet through Azure Load Balancer.
```

### The Architectural Root Cause:
* **AWS ALB (Layer 7):** Acts as a reverse proxy. It terminates client connections and opens a *new* connection from its own subnet IP (`10.0.1.x`).
* **Azure Load Balancer (Layer 4 Pass-Through):** Uses Direct Server Return (DNAT). It does **NOT** rewrite the source IP! Packets forwarded to the VM retain the **client's real public internet IP**!
* **The Firewall Drop:** Our `app_nsg` rule allowed Port 80 only from `source_address_prefix = var.web_subnet_cidr[0]` (`10.0.1.0/24`). Because the packet arrived with the client's public IP, Rule 100 did not match, and Rule 1000 (`Deny-All-Internet-Inbound`) **dropped the packet**!

### The Solution:
In `networking.tf`, updated `azurerm_network_security_group.app_nsg`:
```hcl
security_rule {
  name                       = "Allow-HTTP-Inbound"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "*"   # Allows traffic forwarded by Load Balancer
  destination_address_prefix = "*"
}
```
Applied via `terraform apply -auto-approve`. Traffic immediately flowed through, returning **`HTTP/1.1 200 OK`**!

---

# 🧪 End-to-End Test Suite Verification (12 / 12 Passed)

Automated verification executed via [test-project3.ps1](./test-project3.ps1):

```text
======================================================================
  🏆 PROJECT 3: ENTERPRISE 3-TIER PRODUCTION STACK E2E TEST SUITE
======================================================================

Fetching live Terraform outputs...

>>> [GROUP 1] TIER 1: PUBLIC INGRESS & LOAD BALANCING
 [PASS] Live HTTP 200 OK from Public Load Balancer
        URL: http://20.207.197.39 | Status: 200 OK
 [PASS] Web Landing Page Content Verification
        Verified: 3-Tier Production dashboard HTML rendered by Nginx
 [PASS] Load Balancer Backend Address Pool Membership
        Registered VMSS backend instances in pool: 2

>>> [GROUP 2] TIER 2: PRIVATE VMSS & MANAGED IDENTITY
 [PASS] VMSS Instances Provisioning State
        All 2 / 2 instances report 'Succeeded'
 [PASS] Zero-Public-IP Security Enforcement on VMSS
        Verified: All backend VMs have ZERO public IPs (Internal Subnet 10.0.2.0/24 only)
 [PASS] Microsoft Entra ID Managed Identity Verification
        Managed Identity: id-vmss-enterprise-3tier-dev (Principal ID: a9624e13-7059-4cdc-856f-712a05bc46ce)

>>> [GROUP 3] SECURITY PLANE: AZURE KEY VAULT & SECRETS
 [PASS] Azure Key Vault Active Status
        Key Vault 'kv-3tier-5rc0gz' provisioningState: Succeeded
 [PASS] Key Vault Secret: SQL Admin Password
        Secret 'sql-admin-password' securely stored in hardware safe
 [PASS] Key Vault Secret: 4096-bit RSA SSH Private Key
        Secret 'vmss-ssh-private-key' stored in Key Vault (Zero password SSH)

>>> [GROUP 4] TIER 3: AZURE SQL DATABASE & ZERO-TRUST VNET RULE
 [PASS] Azure SQL Database Status
        Database 'db-enterprise-app' on server 'sql-enterprise-3tier-5rc0gz' is: Online
 [PASS] SQL VNet Firewall Rule (App Subnet Isolation)
        Rule 'sql-vnet-rule-app' state: Ready (Locked to Subnet snet-app-dev)
 [PASS] Zero-Trust Enforcement: Zero Public IP Firewall Bypasses
        Verified: 0 public IP firewall rules exist (Connections strictly restricted to snet-app-dev)

======================================================================
  TEST RESULTS: 12 / 12 TESTS PASSED
======================================================================
🎉 100% PRODUCTION READY! ALL 12 ENTERPRISE ARCHITECTURE TESTS PASSED!
```

---

## 🧹 Teardown & FinOps Cost Management

To guarantee zero billing and protect Azure Free Trial credits:

```powershell
terraform destroy -auto-approve
```

All 28 cloud resources (Compute, Networking, Key Vault, and SQL Database) are cleanly destroyed in under 3 minutes, leaving only your permanent state storage container intact.
