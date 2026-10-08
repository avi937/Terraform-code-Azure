# 🌐 Project 1: Enterprise Multi-Tier VNet & NSG Security Architecture

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AzureRM](https://img.shields.io/badge/AzureRM-v4.81+-0089D6?logo=microsoftazure&logoColor=white)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![Region](https://img.shields.io/badge/Region-Central_India-orange)](#)
[![Status](https://img.shields.io/badge/Status-Completed_✅-brightgreen)](#)

A production-grade, zero-trust cloud network architecture on Microsoft Azure provisioned with Terraform (`azurerm`). Implements isolated multi-tier subnetting, priority-based Network Security Groups (NSGs), remote state locking with Azure Blob Storage, and an automated end-to-end test suite.

---

## 🏛️ Architecture Overview

The infrastructure enforces a strict **Zero-Trust Network Perimeter** across 3 distinct isolation tiers:

```
                      [ Public Internet ]
                               │
                               ▼ (HTTP:80, HTTPS:443 Allowed)
    ┌─────────────────────────────────────────────────────────────┐
    │  Tier 1: Web Subnet (10.0.1.0/24)                           │
    │  NSG: nsg-web-dev                                           │
    └──────────────────────────────┬──────────────────────────────┘
                                   │ (Port 8080 allowed ONLY from Web Subnet)
                                   ▼ (All other inbound blocked - Priority 1000)
    ┌─────────────────────────────────────────────────────────────┐
    │  Tier 2: App Subnet (10.0.2.0/24)                           │
    │  NSG: nsg-app-dev                                           │
    └──────────────────────────────┬──────────────────────────────┘
                                   │ (Port 1433 allowed ONLY from App Subnet)
                                   ▼ (All other inbound blocked - Priority 1000)
    ┌─────────────────────────────────────────────────────────────┐
    │  Tier 3: Database Subnet (10.0.3.0/24)                      │
    │  NSG: nsg-db-dev                                            │
    └─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Key Features

* **AzureRM 4.x Modernization**: Built on `azurerm ~> 4.0` using `resource_provider_registrations = "none"` for optimized deployment speed and elimination of deprecated provider arguments.
* **Isolated Remote State Backend**: Remote state persisted to Azure Blob Storage (`sttfstateavi0025` / container `tfstate`) with automatic blob lease locking to prevent concurrent deployment collisions.
* **Non-Overlapping CIDR Subnetting**: Supernet `10.0.0.0/16` subdivided cleanly into `/24` subnets with headroom for 250+ workloads per tier.
* **Micro-Segmentation Firewalls**:
  * **Web NSG**: Exposes HTTP/HTTPS to the public internet while protecting internal administration ports.
  * **App NSG**: Micro-segmented to accept traffic exclusively on port `8080` from `10.0.1.0/24`. All other inbound traffic denied.
  * **DB NSG**: Restricts database access strictly to port `1433` (MS SQL) from `10.0.2.0/24`. All other inbound traffic denied.
* **Direct Subnet Associations**: Every NSG is explicitly attached at the subnet level rather than per-NIC for uniform boundary security.
* **Automated E2E Testing**: Built-in PowerShell test suite (`test-project1.ps1`) verifying all 18 control-plane conditions and state parity.

---

## 📂 Project Structure

```text
project-1/
├── main.tf             # Resource Group, Virtual Network & Subnets (Web, App, DB)
├── security.tf         # Network Security Groups, Security Rules & Subnet Associations
├── variables.tf        # Input variable declarations with validation defaults
├── outputs.tf          # Resource IDs, VNet Address Spaces, and Subnet metadata
├── provider.tf         # Terraform version constraints & Azure Blob backend config
├── terraform.tfvars    # Environment values (Dev environment, centralindia, tags)
├── test-project1.ps1   # 18-point automated end-to-end verification test suite
└── README.md           # Project documentation and architectural guide
```

---

## 📊 Network & Security Specification

| Tier | Subnet Name | CIDR | Associated NSG | Inbound Allowed | Inbound Blocked |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Tier 1 (Web)** | `snet-web-dev` | `10.0.1.0/24` | `nsg-web-dev` | `80` (HTTP), `443` (HTTPS) from `Internet` | Default Azure rules |
| **Tier 2 (App)** | `snet-app-dev` | `10.0.2.0/24` | `nsg-app-dev` | `8080` from `10.0.1.0/24` (Web) | All other inbound (`*`) |
| **Tier 3 (DB)**  | `snet-db-dev`  | `10.0.3.0/24` | `nsg-db-dev`  | `1433` from `10.0.2.0/24` (App) | All other inbound (`*`) |

---

## 🛠️ Deployment Instructions

### Prerequisites
1. [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) logged in:
   ```powershell
   az login
   az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
   ```
2. [Terraform CLI](https://developer.hashicorp.com/terraform/install) (>= 1.5.0)

### Execution Steps
```powershell
# 1. Initialize Terraform & Remote Backend
terraform init -upgrade

# 2. Validate syntax and configuration
terraform validate

# 3. Preview execution plan
terraform plan

# 4. Provision infrastructure live
terraform apply -auto-approve
```

---

## 🧪 Automated Testing & Verification

An automated verification test script ([`test-project1.ps1`](./test-project1.ps1)) queries the live Azure Cloud Control Plane and validates Terraform state integrity.

Run the test suite:
```powershell
.\test-project1.ps1
```

### Test Suite Execution Output
```text
=====================================================================
  PROJECT 1: END-TO-END INFRASTRUCTURE VERIFICATION TEST SUITE
=====================================================================

--> [1/5] Verifying Resource Group...
 [PASS] Resource Group 'rg-enterprise-net-dev' exists
 [PASS] Resource Group location is 'centralindia'
 [PASS] Resource Group ProvisioningState is 'Succeeded'

--> [2/5] Verifying Virtual Network & Address Space...
 [PASS] Virtual Network 'vnet-enterprise-net-dev' exists
 [PASS] VNet CIDR contains '10.0.0.0/16'

--> [3/5] Verifying 3-Tier Subnets...
 [PASS] Web Subnet ('snet-web-dev') exists with 10.0.1.0/24
 [PASS] App Subnet ('snet-app-dev') exists with 10.0.2.0/24
 [PASS] DB Subnet ('snet-db-dev') exists with 10.0.3.0/24

--> [4/5] Verifying NSG Associations & Security Rules...
 [PASS] Web Subnet has NSG associated
 [PASS] Web NSG allows Inbound HTTP (80) from Internet
 [PASS] Web NSG allows Inbound HTTPS (443) from Internet
 [PASS] App Subnet has NSG associated
 [PASS] App NSG allows port 8080 exclusively from Web Subnet (10.0.1.0/24)
 [PASS] App NSG has default Deny-All inbound rule (Priority 1000)
 [PASS] DB Subnet has NSG associated
 [PASS] DB NSG allows port 1433 exclusively from App Subnet (10.0.2.0/24)
 [PASS] DB NSG has default Deny-All inbound rule (Priority 1000)

--> [5/5] Checking Terraform State Drift...
 [PASS] Terraform State contains all 11 managed resources

=====================================================================
  TEST RESULT: ALL TESTS PASSED (18/18) - 100% HEALTHY
=====================================================================
```

---

## 🧹 Teardown

To destroy all provisioned resources and release cloud costs:
```powershell
terraform destroy -auto-approve
```
