# 🔷 Microsoft Azure Terraform Infrastructure Portfolio

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Azure Provider](https://img.shields.io/badge/Azure_Provider-azurerm_3.0+-0089D6?logo=microsoftazure&logoColor=white)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![Architecture](https://img.shields.io/badge/Architecture-Enterprise_Multi--Cloud-blue?logo=azuredevops&logoColor=white)](#)

A structured collection of production-grade Microsoft Azure Infrastructure as Code (IaC) architectures built with Terraform (`azurerm`). Designed with enterprise security, remote state tracking, modular networking, and zero-trust identity management.

---

## 📂 Projects Directory

| # | Project | Description | Status |
| :---: | :--- | :--- | :---: |
| **01** | [**Project 1: Enterprise Multi-Tier VNet & NSG**](./project-1/README.md) | Modular Resource Groups, Multi-Tier Subnetting (Web, App, DB), Priority-based NSG firewalls, and Azure Storage remote state backend. | `Completed ✅` |
| **02** | [**Project 2: High Availability & VMSS Auto-Scaling**](./project-2/) | Virtual Machine Scale Sets (VMSS) behind an Azure Load Balancer with dynamic CPU-based autoscaling rules. | *Planned 📅* |
| **03** | [**Project 3: Enterprise 3-Tier Web Application**](./project-3/) | Public Load Balancer &rarr; Private VMSS Web Tier &rarr; Private Azure SQL Database with Azure Key Vault & Managed Identities. | *Planned 📅* |

---

## 🛠️ Global Prerequisites

1. **Terraform CLI** (>= 1.5.0): `terraform -version`
2. **Azure CLI** (`az`) authenticated:
   ```bash
   az login --tenant 341ac587-04bc-4841-ad94-a834b8906a56
   az account show
   ```
