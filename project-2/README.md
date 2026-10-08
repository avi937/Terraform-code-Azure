# 🚀 Project 2: High Availability & VMSS Auto-Scaling Architecture

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AzureRM](https://img.shields.io/badge/AzureRM-v4.81+-0089D6?logo=microsoftazure&logoColor=white)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![OS](https://img.shields.io/badge/OS-Ubuntu_22.04_LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Region](https://img.shields.io/badge/Region-Central_India_(Zone_1)-orange)](#)
[![Status](https://img.shields.io/badge/Status-Completed_✅-brightgreen)](#)

A production-grade, highly available, and dynamically autoscaled compute fleet built on Microsoft Azure using Terraform (`azurerm`). Implements an Azure Standard Load Balancer, Linux Virtual Machine Scale Sets (VMSS) running NGINX, Cloud-Init automated bootstrapping, zero-trust cryptographic SSH keys, and reactive CPU-based Azure Monitor Autoscale policies.

---

## 🏛️ Architecture Overview

Project 2 consumes the foundational networking from **Project 1** via decoupled remote state and establishes a resilient compute tier:

```
                   [ Users on the Internet ]
                               │
                               ▼ HTTP (Port 80)
                ┌──────────────────────────────┐
                │  Static Azure Public IP      │
                │  (pip-ha-vmss-dev)           │
                └──────────────┬───────────────┘
                               │
                               ▼
                ┌──────────────────────────────┐
                │ Azure Standard Load Balancer │
                │ • HTTP Health Probe: Port 80 │
                │ • Load Balancing Rule        │
                └──────────────┬───────────────┘
                               │
                 Backend Address Pool Traffic
                               │
        ┌──────────────────────┴──────────────────────┐
        ▼                                             ▼
┌───────────────────────────────┐   ┌───────────────────────────────┐
│ VMSS Instance 0 (10.0.1.4)    │   │ VMSS Instance 2 (10.0.1.5)    │
│ • Zone: 1 (Central India)     │   │ • Zone: 1 (Central India)     │
│ • Subnet: snet-web-dev        │   │ • Subnet: snet-web-dev        │
│ • NGINX Web Server            │   │ • NGINX Web Server            │
└───────────────────────────────┘   └───────────────────────────────┘
        ▲                                             ▲
        └──────────────────────┬──────────────────────┘
                               │
                 [ Azure Monitor Autoscale ]
                 • Scale-Out: Average CPU > 75% for 5 mins (+1 VM)
                 • Scale-In:  Average CPU < 25% for 5 mins (-1 VM)
                 • Cooldown:  5 mins (PT5M)
```

---

## 🚀 Key Features

* **Decoupled State Architecture**: Uses `data "terraform_remote_state" "network"` to dynamically read VNet, Subnet (`snet-web-dev`), and Resource Group IDs directly from Project 1 without hardcoding IDs or sharing blast radiuses.
* **Azure Standard Load Balancer**:
  * Static Public IP with Standard SKU.
  * Layer 4 traffic distribution across backend instances.
  * Health Probe pings port `80` every 15 seconds to ensure zero downtime.
* **Linux Virtual Machine Scale Set (VMSS)**:
  * Ubuntu 22.04 LTS Gen2 running on `Standard_B2s_v2` burstable nodes.
  * Pinned to **Availability Zone 1** for guaranteed capacity in Central India.
  * Cloud-Init script automatically installs NGINX and configures a dynamic landing page reporting hostname, private IP, and health status.
* **Zero-Trust Security**:
  * Password authentication is completely disabled (`disable_password_authentication = true`).
  * Dedicated 4096-bit RSA SSH key pair generated in Terraform.
  * Private key saved locally to `id_rsa.pem` and protected from Git via `.gitignore`.
* **Reactive Azure Monitor Autoscale**:
  * Samples CPU usage every 1 minute (`PT1M`) over a 5-minute rolling window (`PT5M`).
  * Scales out by +1 VM when average CPU exceeds 75%.
  * Scales in by -1 VM when average CPU drops below 25%.
  * Enforces a 5-minute cooldown (`PT5M`) to prevent rapid scaling oscillation (flapping).

---

## 📂 Project Structure

```text
project-2/
├── provider.tf         # AzureRM v4, TLS, Local providers & Project 1 remote state data block
├── variables.tf        # VM SKU, capacity limits (min 1, max 2), and common tags
├── load_balancer.tf    # Public IP, Standard LB, Backend Pool, Probe & LB Rules
├── vmss.tf             # Linux VMSS in Zone 1, Cloud-Init script, NIC & SSH key generation
├── autoscale.tf        # Azure Monitor Autoscale CPU triggers and scaling profiles
├── outputs.tf          # Load balancer URL, public IP, and VMSS metadata
├── test-project2.ps1   # 19-point automated end-to-end verification test suite
└── README.md           # Project documentation and architectural guide
```

---

## 📊 Deployment Specifications

| Resource | Specification | Details |
| :--- | :--- | :--- |
| **Region & Zone** | Central India, Zone 1 | `centralindia`, `zones = ["1"]` |
| **VM SKU** | `Standard_B2s_v2` | 2 vCPUs, 8 GB RAM (Burstable v2) |
| **Fleet Capacity** | Default: 2, Min: 1, Max: 2 | Aligned with subscription regional vCPU limits |
| **OS Image** | Ubuntu 22.04 LTS Gen2 | `Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2` |
| **Subnet Placement** | Project 1 Web Subnet | `10.0.1.0/24` (`snet-web-dev`) |
| **Load Balancer** | Azure Standard LB | HTTP Port 80 forward & probe |
| **Authentication** | 4096-bit RSA Key Pair | `./id_rsa.pem` (Password auth disabled) |

---

## 🛠️ Deployment Instructions

### Prerequisites
1. Project 1 must be deployed (provides `snet-web-dev` and remote state).
2. Azure CLI logged in and authenticated.

### Execution Steps
```powershell
# 1. Navigate to project-2 directory
cd D:\terraform-AWS\Terraform-code-Azure\project-2

# 2. Initialize Terraform & Remote Backend
terraform init

# 3. Validate configuration
terraform validate

# 4. Preview execution plan
terraform plan

# 5. Provision the High-Availability fleet live
terraform apply -auto-approve
```

---

## 🧪 Automated Testing & Live Verification

### 1. Automated Verification Suite
Run the built-in 19-point verification script:
```powershell
.\test-project2.ps1
```

```text
=====================================================================
  PROJECT 2: END-TO-END HIGH AVAILABILITY & AUTOSCALE TEST SUITE
=====================================================================

--> [1/5] Verifying Public IP & Standard Load Balancer...
 [PASS] Public IP 'pip-ha-vmss-dev' is allocated
 [PASS] Public IP SKU is 'Standard'
 [PASS] Standard Load Balancer 'lb-ha-vmss-dev' exists
 [PASS] Load Balancer has Backend Address Pool
 [PASS] Load Balancer has HTTP Health Probe on port 80

--> [2/5] Testing Live HTTP Web Traffic via Load Balancer...
 [PASS] Load Balancer endpoint responds with HTTP 200
 [PASS] Webpage serves custom Project 2 HTML content
 [PASS] Webpage displays 'LIVE HEALTHY INSTANCE' status

--> [3/5] Verifying VMSS Fleet & Placement Subnet...
 [PASS] VMSS 'vmss-ha-vmss-dev' exists and is Provisioned
 [PASS] VMSS uses verified SKU 'Standard_B2s_v2'
 [PASS] VMSS is pinned to Availability Zone '1'
 [PASS] VMSS instances are active and healthy
 [PASS] VMSS instance is placed inside Project 1 Web Subnet (10.0.1.0/24)

--> [4/5] Verifying Azure Monitor Autoscale Settings...
 [PASS] Autoscale Setting 'autoscale-ha-vmss-dev' is Enabled
 [PASS] Autoscale Min limit is 1 and Max limit is 2
 [PASS] Scale-Out Rule: Triggered when CPU > 75% for 5 mins (+1 VM)
 [PASS] Scale-In Rule: Triggered when CPU < 25% for 5 mins (-1 VM)

--> [5/5] Verifying Local SSH Key & Git Protection...
 [PASS] Local private SSH key 'id_rsa.pem' exists
 [PASS] Private key is protected from Git by .gitignore (*.pem)

=====================================================================
  TEST RESULT: ALL TESTS PASSED (19/19) - 100% HEALTHY
=====================================================================
```

---

### 2. Live CPU Auto-Scale Stress Test Validation
To verify dynamic scaling under high CPU load:

1. **Trigger a 6-minute CPU stress loop on instance 0:**
   ```powershell
   az vmss run-command invoke --resource-group rg-enterprise-net-dev --name vmss-ha-vmss-dev --instance-id 0 --command-id RunShellScript --scripts "for i in 1 2; do yes > /dev/null & done; sleep 360; killall yes"
   ```

2. **Verify the Scale-Out event in Azure Monitor:**
   * After 5 minutes at **99.6% CPU utilization**, Azure Monitor triggered the Scale-Out rule.
   * Instance 2 (`10.0.1.5`) was automatically provisioned in Zone 1.
   * The Load Balancer immediately began distributing live traffic across both instances (`10.0.1.4` and `10.0.1.5`).

---

## 🧹 Teardown

To destroy the compute resources and release cloud costs:
```powershell
terraform destroy -auto-approve
```
*(Note: Destroying Project 2 leaves Project 1's network intact and untouched).*
