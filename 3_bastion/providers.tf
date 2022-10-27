terraform {
  cloud {
    organization = var.tf-org

    workspaces {
      name = var.tf-ws-bastion
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
