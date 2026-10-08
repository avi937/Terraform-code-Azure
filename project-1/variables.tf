variable "project_name" {
  description = "Name of the project used for standardized resource naming"
  type        = string
  default     = "enterprise-net"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Primary Azure region for all deployed resources"
  type        = string
  default     = "centralindia"
}

variable "vnet_address_space" {
  description = "Address space CIDR block for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "web_subnet_cidr" {
  description = "Subnet CIDR for the public Web tier"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "app_subnet_cidr" {
  description = "Subnet CIDR for the private Application tier"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "db_subnet_cidr" {
  description = "Subnet CIDR for the private Database tier"
  type        = list(string)
  default     = ["10.0.3.0/24"]
}

variable "common_tags" {
  description = "Enterprise tags attached to all resources for FinOps governance & billing"
  type        = map(string)
  default = {
    Environment = "Dev"
    ManagedBy   = "Terraform"
    Project     = "Azure-Portfolio-Phase2"
    Owner       = "Avi Arora"
  }
}
