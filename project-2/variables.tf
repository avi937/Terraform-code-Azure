variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "ha-vmss"
}

variable "vm_sku" {
  description = "Azure Virtual Machine size SKU"
  type        = string
  default     = "Standard_B2s_v2" # Available in Central India Zone 1
}

variable "admin_username" {
  description = "Administrator username for Linux VMs"
  type        = string
  default     = "azureuser"
}

variable "instance_count" {
  description = "Default number of VM instances in the scale set"
  type        = number
  default     = 2
}

variable "min_instances" {
  description = "Minimum number of instances for autoscale"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances for autoscale"
  type        = number
  default     = 2 # Keeps within subscription quota limit of 4 vCPUs (2 x 2 vCPUs)
}

variable "common_tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    Project     = "Azure-Portfolio-Phase2"
    ManagedBy   = "Terraform"
    Environment = "Dev"
    Owner       = "Avi Arora"
  }
}
