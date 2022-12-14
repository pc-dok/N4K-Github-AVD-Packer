terraform {
  cloud {
    organization = "N4K"

    workspaces {
      name = "2_Github-AVD-AADDS"
    }
  }
  
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.10"
    }
  }
}

provider "azurerm" {
  subscription_id = var.ARM_SUBSCRIPTION
  client_id       = var.ARM_CLIENT_ID
  client_secret   = var.ARM_CLIENT_SECRET
  tenant_id       = var.ARM_TENANT_ID
  features {}
}

provider "github" {
  token = var.GITHUB_SECRET
  owner = var.GITHUB_OWNER
}
