terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  # Dedicated Remote State Backend for Project 2
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-dev"
    storage_account_name = "sttfstateavi0025"
    container_name       = "tfstate"
    key                  = "project-2/terraform.tfstate"
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"
  features {}
}

# Dynamically consume network outputs from Project 1
data "terraform_remote_state" "network" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-tfstate-dev"
    storage_account_name = "sttfstateavi0025"
    container_name       = "tfstate"
    key                  = "project-1/terraform.tfstate"
  }
}
