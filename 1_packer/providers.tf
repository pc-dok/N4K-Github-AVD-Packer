terraform {
  cloud {
    organization = "N4K"

    workspaces {
      name = "1_Github-AVD-Packer"
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
  token = "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"
  owner = "pc-dok"
}

#provider "github" {
#  token = var.GITHUB_SECRET
#  owner = var.GITHUB_OWNER
#}

