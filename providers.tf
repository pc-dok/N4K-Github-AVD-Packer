terraform {

  cloud {
    organization = "N4K"

    workspaces {
      name = "N4K-Github-AVD-Packer"
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
