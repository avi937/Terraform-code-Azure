terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Official Azure Resource Manager provider v4.0+
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # Random provider: generates unique names & DB passwords
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    # TLS provider: generates 4096-bit RSA SSH Key pairs
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Isolated Remote State Backend for Project 3
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-dev"
    storage_account_name = "sttfstateavi0025"
    container_name       = "tfstate"
    key                  = "project-3/terraform.tfstate"
  }
}

provider "azurerm" {
  # The modern v4.0 syntax that stops Azure from scanning 40+ unused providers
  resource_provider_registrations = "none"

  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
