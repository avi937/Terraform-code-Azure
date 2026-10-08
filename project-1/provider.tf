terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Isolated Remote State Backend for Project 1
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-dev"
    storage_account_name = "sttfstateavi0025"
    container_name       = "tfstate"
    key                  = "project-1/terraform.tfstate"
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"
  features {}
}
