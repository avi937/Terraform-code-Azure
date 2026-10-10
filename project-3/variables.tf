# ==============================================================================
# PROJECT & ENVIRONMENT METADATA
# ==============================================================================
variable "project_name" {
  description = "Name of the project used for consistent resource naming"
  type        = string
  default     = "enterprise-3tier"
}

variable "environment" {
  description = "Target deployment environment"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Primary Azure region for all deployed resources"
  type        = string
  default     = "centralindia"
}

# ==============================================================================
# NETWORK ADDRESS SPACES (3-TIER ARCHITECTURE)
# ==============================================================================
variable "vnet_address_space" {
  description = "CIDR block for the overall Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "web_subnet_cidr" {
  description = "Subnet CIDR for Tier 1: Public Load Balancer"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "app_subnet_cidr" {
  description = "Subnet CIDR for Tier 2: Private VMSS Compute"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "db_subnet_cidr" {
  description = "Subnet CIDR for Tier 3: Private Azure SQL Database"
  type        = list(string)
  default     = ["10.0.3.0/24"]
}

# ==============================================================================
# COMPUTE CONFIGURATION (VMSS)
# ==============================================================================
variable "vm_sku" {
  description = "Azure VM Size (Standard_B2ats_v2 has verified quota in Central India at ~$0.0062/hr)"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "admin_username" {
  description = "Administrator username for the VMSS Linux instances"
  type        = string
  default     = "azureuser"
}

variable "instance_count" {
  description = "Default number of VM instances in the Scale Set"
  type        = number
  default     = 2
}

# ==============================================================================
# GOVERNANCE & FINOPS TAGS
# ==============================================================================
variable "common_tags" {
  description = "Tags applied to all resources for cost tracking and ownership"
  type        = map(string)
  default = {
    Environment = "Dev"
    Project     = "Azure-Portfolio-Phase2"
    Owner       = "Avi Arora"
    ManagedBy   = "Terraform"
  }
}
