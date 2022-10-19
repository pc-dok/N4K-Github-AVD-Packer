/*
# Create first the RGs for Packer Build and than create the Package with the packer build command in the packer_files directory
#
# Windows Desktop 11
# az vm image list-skus --offer windows-11 --publisher MicrosoftWindowsDesktop --query "[*].name" --location westeurope --out table
# az vm image list --sku win11-22h2-avd --offer windows-11 --publisher MicrosoftWindowsDesktop --query "[*].version" --out tsv --all

packer build \
  -var "artifacts_resource_group=$(terraform output -raw packer_artifacts_resource_group)" \
  -var "build_resource_group=$(terraform output -raw packer_build_resource_group)" \
  -var "client_id=$(terraform output -raw packer_client_id)" \
  -var "client_secret=$(terraform output -raw packer_client_secret)" \
  -var "subscription_id=$(terraform output -raw packer_subscription_id)" \
  -var "tenant_id=$(terraform output -raw packer_tenant_id)" \
  -var "source_image_publisher=MicrosoftWindowsDesktop" \
  -var "source_image_offer=windows-11" \
  -var "source_image_sku=win11-22h2-avd" \
  -var "source_image_version=22621.674.221008" \
  .
 
# Windows Server 2022
# az vm image list-skus --offer WindowsServer --publisher MicrosoftWindowsServer --query "[*].name" --location westeurope --out table
# az vm image list --sku 2022-datacenter --offer WindowsServer --publisher MicrosoftWindowsServer --query "[*].version" --out tsv --all
  
packer build \
  -var "artifacts_resource_group=$(terraform output -raw packer_artifacts_resource_group)" \
  -var "build_resource_group=$(terraform output -raw packer_build_resource_group)" \
  -var "client_id=$(terraform output -raw packer_client_id)" \
  -var "client_secret=$(terraform output -raw packer_client_secret)" \
  -var "subscription_id=$(terraform output -raw packer_subscription_id)" \
  -var "tenant_id=$(terraform output -raw packer_tenant_id)" \
  -var "source_image_publisher=MicrosoftWindowsServer" \
  -var "source_image_offer=WindowsServer" \
  -var "source_image_sku=2022-datacenter" \
  -var "source_image_version=20348.887.220806" \
  .

*/

# Packer Resource Groups

resource "azurerm_resource_group" "packer_artifacts" {
  name     = var.artifacts
  location = var.location
}

resource "azurerm_resource_group" "packer_build" {
  name     = var.builder
  location = var.location
}

# Service Principal Used By Packer

resource "azuread_application" "packer" {
  display_name = "n4k-we-app-packer-avd"
}

resource "azuread_service_principal" "packer" {
  application_id = azuread_application.packer.application_id
}

resource "azuread_service_principal_password" "packer" {
  service_principal_id = azuread_service_principal.packer.id
}

# RBAC
# Grant service principal `Reader` role scoped to subscription
# Grant service principal `Contributor` role scoped to Packer resource groups

data "azurerm_subscription" "subscription" {}

resource "azurerm_role_assignment" "subscription_reader" {
  scope                = data.azurerm_subscription.subscription.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.packer.id
}

resource "azurerm_role_assignment" "packer_build_contributor" {
  scope                = azurerm_resource_group.packer_build.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.packer.id
}

resource "azurerm_role_assignment" "packer_artifacts_contributor" {
  scope                = azurerm_resource_group.packer_artifacts.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.packer.id
}

# Export Variables For Packer

resource "github_repository" "packer_windows_avd" {
  name        = "N4K-Github-AVD-Packer-Build"
  description = "Create Win11 and Win2033 Images with Packer"
  visibility  = "private"
  auto_init   = true
}

# Azure CLI Authentication

resource "github_actions_secret" "github_actions_azure_credentials" {
  repository  = github_repository.packer_windows_avd.name
  secret_name = "AZURE_CREDENTIALS"

  plaintext_value = jsonencode(
    {
      clientId       = azuread_application.packer.application_id
      clientSecret   = azuread_service_principal_password.packer.value
      subscriptionId = data.azurerm_subscription.subscription.subscription_id
      tenantId       = data.azurerm_subscription.subscription.tenant_id
    }
  )
}

# Packer Authentication

resource "github_actions_secret" "packer_client_id" {
  repository      = github_repository.packer_windows_avd.name
  secret_name     = "PACKER_CLIENT_ID"
  plaintext_value = azuread_application.packer.application_id
}

resource "github_actions_secret" "packer_client_secret" {
  repository      = github_repository.packer_windows_avd.name
  secret_name     = "PACKER_CLIENT_SECRET"
  plaintext_value = azuread_service_principal_password.packer.value
}

resource "github_actions_secret" "packer_subscription_id" {
  repository      = github_repository.packer_windows_avd.name
  secret_name     = "PACKER_SUBSCRIPTION_ID"
  plaintext_value = data.azurerm_subscription.subscription.subscription_id
}

resource "github_actions_secret" "packer_tenant_id" {
  repository      = github_repository.packer_windows_avd.name
  secret_name     = "PACKER_TENANT_ID"
  plaintext_value = data.azurerm_subscription.subscription.tenant_id
}

# Packer Resource Groups

resource "github_actions_secret" "packer_artifacts_resource_group" {
  repository      = github_repository.packer_windows_avd.name
  secret_name     = "PACKER_ARTIFACTS_RESOURCE_GROUP"
  plaintext_value = azurerm_resource_group.packer_artifacts.name
}

resource "github_actions_secret" "packer_build_resource_group" {
  repository      = github_repository.packer_windows_avd.name
  secret_name     = "PACKER_BUILD_RESOURCE_GROUP"
  plaintext_value = azurerm_resource_group.packer_build.name
}

resource "github_repository_file" "foo" {
  repository          = github_repository.packer_windows_avd.name
  branch              = "main"
  file                = ".gitignore"
  content             = "**/*.tfstate"
  commit_message      = "Managed by Terraform"
  overwrite_on_create = true
}

# Outputs to run Packer locally

output "packer_artifacts_resource_group" {
  value = azurerm_resource_group.packer_artifacts.name
}

output "packer_build_resource_group" {
  value = azurerm_resource_group.packer_build.name
}

output "packer_client_id" {
  value     = azuread_application.packer.application_id
  sensitive = true
}

output "packer_client_secret" {
  value     = azuread_service_principal_password.packer.value
  sensitive = true
}

output "packer_subscription_id" {
  value     = data.azurerm_subscription.subscription.subscription_id
  sensitive = true
}

output "packer_tenant_id" {
  value     = data.azurerm_subscription.subscription.tenant_id
  sensitive = true
}
