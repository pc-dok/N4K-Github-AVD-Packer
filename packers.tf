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

resource "github_repository_file" "biceps" {
  repository          = github_repository.packer_windows_avd.name
  branch              = "main"
  file                = "cleanup-resource-group.bicep"
  content             = ""
  commit_message      = "Create cleanup-resource-group.bicep"
  overwrite_on_create = true
}

resource "github_repository_file" "packages" {
  repository          = github_repository.packer_windows_avd.name
  branch              = "main"
  file                = "packages.config"
  content             = <<-EOT
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <!-- FSLogix -->
  <package id="fslogix" />

  <!-- Editors -->
  <package id="notepadplusplus" />

  <!-- Common Apps -->
  <package id="7zip" />
  <package id="foxitreader" />
  <package id="keepassxc" />
</packages>
EOT
  
  commit_message      = "Create packages.config"
  overwrite_on_create = true
}

resource "github_repository_file" "installposhaz" {
  repository          = github_repository.packer_windows_avd.name
  branch              = "main"
  file                = "install-azure-powershell.ps1"
  content             = <<-EOT
$ErrorActionPreference = "Stop"

$downloadUrl = "https://github.com/Azure/azure-powershell/releases/download/v7.3.2-March2022/Az-Cmdlets-7.3.2.35305-x64.msi"
$outFile = "D:\az_pwsh.msi" # temporary disk

Write-Host "Downloading $downloadUrl ..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $downloadUrl -OutFile $outFile

Write-Host "Installing AZ Shell CMD"
Start-Process "msiexec.exe" -Wait -ArgumentList "/package $outFile"

#Add Windows Features for Administrate than AADDS with this Client
Write-Host "Add Windows Features - RSAT Tools - for Active Directory Management"
Add-WindowsFeature "RSAT-AD-Tools" -verbose

Write-Host "Add Windows Features DNS Management"
Add-WindowsFeature -Name "dns" -IncludeAllSubFeature -IncludeManagementTools -verbose

Write-Host "Add Windows Features GPMC Management"
Add-WindowsFeature -Name "gpmc" -IncludeAllSubFeature -IncludeManagementTools -verbose

#Disable Server Manager on Logon
Write-Host "Disable Server Manager on Logon"
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

Write-Host "All done!"
EOT
  
  commit_message      = "Create install-azure-powershell.ps1"
  overwrite_on_create = true
}

resource "github_repository_file" "serverpkrhcl" {
  repository          = github_repository.packer_windows_avd.name
  branch              = "main"
  file                = "server.pkr.hcl"
  content             = <<-EOT
    
# Server 2022  
variable "client_id" {
  type        = string
  description = "Azure Service Principal App ID."
  sensitive   = true
}

variable "client_secret" {
  type        = string
  description = "Azure Service Principal Secret."
  sensitive   = true
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID."
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID."
  sensitive   = true
}

variable "artifacts_resource_group" {
  type        = string
  description = "Packer Artifacts Resource Group."
}

variable "build_resource_group" {
  type        = string
  description = "Packer Build Resource Group."
}

variable "source_image_publisher" {
  type        = string
  description = "Windows Image Publisher."
}

variable "source_image_offer" {
  type        = string
  description = "Windows Image Offer."
}

variable "source_image_sku" {
  type        = string
  description = "Windows Image SKU."
}

variable "source_image_version" {
  type        = string
  description = "Windows Image Version."
}

source "azure-arm" "avd" {
  # WinRM Communicator

  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "5m"
  winrm_username = "packer"

  # Service Principal Authentication

  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # Source Image

  os_type         = "Windows"
  image_publisher = var.source_image_publisher
  image_offer     = var.source_image_offer
  image_sku       = var.source_image_sku
  image_version   = var.source_image_version

  # Destination Image

  managed_image_resource_group_name = var.artifacts_resource_group
  managed_image_name                = "$${var.source_image_sku}-$${var.source_image_version}"

  # Packer Computing Resources

  build_resource_group_name = var.build_resource_group
  vm_size                   = "Standard_D4ds_v4"
}

build {
  source "azure-arm.avd" {}

  # Install Chocolatey: https://chocolatey.org/install#individual
  provisioner "powershell" {
    inline = ["Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"]
  }

  # Install Chocolatey packages
  provisioner "file" {
    source      = "./packages.config"
    destination = "D:/packages.config"
  }

  provisioner "powershell" {
    inline = ["choco install --confirm D:/packages.config"]
    # See https://docs.chocolatey.org/en-us/choco/commands/install#exit-codes
    valid_exit_codes = [0, 3010]
  }

  provisioner "windows-restart" {}

  # Azure PowerShell Modules
  provisioner "powershell" {
    script = "./install-azure-powershell.ps1"
  }

  # Generalize image using Sysprep
  # See https://www.packer.io/docs/builders/azure/arm#windows
  # See https://docs.microsoft.com/en-us/azure/virtual-machines/windows/build-image-with-packer#define-packer-template
  provisioner "powershell" {
    inline = [
      "while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
      "while ($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]
  }
}
# End
EOT
  
  commit_message      = "Create server.pkr.hcl"
  overwrite_on_create = true
}

resource "github_repository_file" "win11pkrhcl" {
  repository          = github_repository.packer_windows_avd.name
  branch              = "main"
  file                = "windows.pkr.hcl"
  content             = <<-EOT
# Windows 11  
variable "client_id" {
  type        = string
  description = "Azure Service Principal App ID."
  sensitive   = true
}

variable "client_secret" {
  type        = string
  description = "Azure Service Principal Secret."
  sensitive   = true
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID."
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID."
  sensitive   = true
}

variable "artifacts_resource_group" {
  type        = string
  description = "Packer Artifacts Resource Group."
}

variable "build_resource_group" {
  type        = string
  description = "Packer Build Resource Group."
}

variable "source_image_publisher" {
  type        = string
  description = "Windows Image Publisher."
}

variable "source_image_offer" {
  type        = string
  description = "Windows Image Offer."
}

variable "source_image_sku" {
  type        = string
  description = "Windows Image SKU."
}

variable "source_image_version" {
  type        = string
  description = "Windows Image Version."
}

source "azure-arm" "avd" {
  # WinRM Communicator

  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "5m"
  winrm_username = "packer"

  # Service Principal Authentication

  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # Source Image

  os_type         = "Windows"
  image_publisher = var.source_image_publisher
  image_offer     = var.source_image_offer
  image_sku       = var.source_image_sku
  image_version   = var.source_image_version

  # Destination Image

  managed_image_resource_group_name = var.artifacts_resource_group
  managed_image_name                = "$${var.source_image_sku}-$${var.source_image_version}"

  # Packer Computing Resources

  build_resource_group_name = var.build_resource_group
  vm_size                   = "Standard_D4ds_v4"
}

build {
  source "azure-arm.avd" {}

  # Install Chocolatey: https://chocolatey.org/install#individual
  provisioner "powershell" {
    inline = ["Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"]
  }

  # Install Chocolatey packages
  provisioner "file" {
    source      = "./packages.config"
    destination = "D:/packages.config"
  }

  provisioner "powershell" {
    inline = ["choco install --confirm D:/packages.config"]
    # See https://docs.chocolatey.org/en-us/choco/commands/install#exit-codes
    valid_exit_codes = [0, 3010]
  }

  provisioner "windows-restart" {}

  # Azure PowerShell Modules
  #provisioner "powershell" {
  #  script = "./install-azure-powershell.ps1"
  #}

  # Generalize image using Sysprep
  # See https://www.packer.io/docs/builders/azure/arm#windows
  # See https://docs.microsoft.com/en-us/azure/virtual-machines/windows/build-image-with-packer#define-packer-template
  provisioner "powershell" {
    inline = [
      "while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
      "while ($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]
  }
}
#End
EOT
  
  commit_message      = "Create windows.pkr.hcl"
  overwrite_on_create = true
}

resource "github_repository_file" "packerserver2022yml" {
  repository          = github_repository.packer_windows_avd.name
  branch              = "main"
  file                = ".github/workflows/packer_server2022.yml"
  content             = <<-EOT
name: Packer Server 2022

on:
  push:
    branches:
      - main
  schedule:
    - cron: 1 * * * *

env:
  IMAGE_PUBLISHER: MicrosoftWindowsServer
  IMAGE_OFFER: WindowsServer
  IMAGE_SKU: 2022-datacenter-azure-edition-smalldisk

jobs:
  latest_windows_version:
    name: Get latest Windows version from Azure
    runs-on: ubuntu-latest
    outputs:
      version: $${{ steps.get_latest_version.outputs.version }}
    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: $${{ secrets.AZURE_CREDENTIALS }}

      - name: Get Latest Version
        id: get_latest_version
        uses: azure/CLI@v1
        with:
          azcliversion: 2.34.1
          inlineScript: |
            latest_version=$(
              az vm image list \
                --publisher "$${IMAGE_PUBLISHER}" \
                --offer "$${IMAGE_OFFER}" \
                --sku "$${IMAGE_SKU}" \
                --all \
                --query "[*].version | sort(@)[-1:]" \
                --out tsv
            )

            echo "Publisher: $${IMAGE_PUBLISHER}"
            echo "Offer:     $${IMAGE_OFFER}"
            echo "SKU:       $${IMAGE_SKU}"
            echo "Version:   $${latest_version}"

            echo "::set-output name=version::$${latest_version}"

  check_image_exists:
    name: Check if latest version has already been built
    runs-on: ubuntu-latest
    needs: latest_windows_version
    outputs:
      exists: $${{ steps.get_image.outputs.exists }}
    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: $${{ secrets.AZURE_CREDENTIALS }}

      - name: Check If Image Exists
        id: get_image
        uses: azure/CLI@v1
        with:
          azcliversion: 2.34.1
          inlineScript: |
            if az image show \
              --resource-group "$${{ secrets.PACKER_ARTIFACTS_RESOURCE_GROUP }}" \
              --name "$${IMAGE_SKU}-$${{ needs.latest_windows_version.outputs.version }}"; then
              image_exists=true
            else
              image_exists=false
            fi

            echo "Image Exists: $${image_exists}"
            echo "::set-output name=exists::$${image_exists}"

  packer:
    name: Run Packer
    runs-on: ubuntu-latest
    needs: [latest_windows_version, check_image_exists]
    if: needs.check_image_exists.outputs.exists == 'false'
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2

      - name: Validate Packer Template
        uses: hashicorp/packer-github-actions@master
        with:
          command: validate
          arguments: -syntax-only
          target: server.pkr.hcl

      - name: Build Packer Image
        uses: hashicorp/packer-github-actions@master
        with:
          command: build
          arguments: -color=false -on-error=abort
          target: server.pkr.hcl
        env:
          PKR_VAR_client_id: $${{ secrets.PACKER_CLIENT_ID }}
          PKR_VAR_client_secret: $${{ secrets.PACKER_CLIENT_SECRET }}
          PKR_VAR_subscription_id: $${{ secrets.PACKER_SUBSCRIPTION_ID }}
          PKR_VAR_tenant_id: $${{ secrets.PACKER_TENANT_ID }}
          PKR_VAR_artifacts_resource_group: $${{ secrets.PACKER_ARTIFACTS_RESOURCE_GROUP }}
          PKR_VAR_build_resource_group: $${{ secrets.PACKER_BUILD_RESOURCE_GROUP }}
          PKR_VAR_source_image_publisher: $${{ env.IMAGE_PUBLISHER }}
          PKR_VAR_source_image_offer: $${{ env.IMAGE_OFFER }}
          PKR_VAR_source_image_sku: $${{ env.IMAGE_SKU }}
          PKR_VAR_source_image_version: $${{ needs.latest_windows_version.outputs.version }}

  cleanup:
    name: Cleanup Packer Resources
    runs-on: ubuntu-latest
    needs: packer
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: $${{ secrets.AZURE_CREDENTIALS }}

      - name: Cleanup Resource Group
        uses: azure/CLI@v1
        with:
          azcliversion: 2.34.1
          inlineScript: |
            az deployment group create \
              --mode Complete \
              --resource-group "$${{ secrets.PACKER_BUILD_RESOURCE_GROUP }}" \
              --template-file cleanup-resource-group.bicep
EOT
  
  commit_message      = "Create packer_server2022.yml"
  overwrite_on_create = true
}              

resource "github_repository_file" "packerwin11yml" {
  repository          = github_repository.packer_windows_avd.name
  branch              = "main"
  file                = ".github/workflows/packer_win11.yml"
  content             = <<-EOT
name: Packer Windows 11

on:
  push:
    branches:
      - main
  schedule:
    - cron: 30 * * * *

env:
  IMAGE_PUBLISHER: MicrosoftWindowsDesktop
  IMAGE_OFFER: windows-11
  IMAGE_SKU: win11-22h2-avd

jobs:
  latest_windows_version:
    name: Get latest Windows version from Azure
    runs-on: ubuntu-latest
    outputs:
      version: $${{ steps.get_latest_version.outputs.version }}
    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: $${{ secrets.AZURE_CREDENTIALS }}

      - name: Get Latest Version
        id: get_latest_version
        uses: azure/CLI@v1
        with:
          azcliversion: 2.34.1
          inlineScript: |
            latest_version=$(
              az vm image list \
                --publisher "$${IMAGE_PUBLISHER}" \
                --offer "$${IMAGE_OFFER}" \
                --sku "$${IMAGE_SKU}" \
                --all \
                --query "[*].version | sort(@)[-1:]" \
                --out tsv
            )

            echo "Publisher: $${IMAGE_PUBLISHER}"
            echo "Offer:     $${IMAGE_OFFER}"
            echo "SKU:       $${IMAGE_SKU}"
            echo "Version:   $${latest_version}"

            echo "::set-output name=version::$${latest_version}"

  check_image_exists:
    name: Check if latest version has already been built
    runs-on: ubuntu-latest
    needs: latest_windows_version
    outputs:
      exists: $${{ steps.get_image.outputs.exists }}
    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: $${{ secrets.AZURE_CREDENTIALS }}

      - name: Check If Image Exists
        id: get_image
        uses: azure/CLI@v1
        with:
          azcliversion: 2.34.1
          inlineScript: |
            if az image show \
              --resource-group "$${{ secrets.PACKER_ARTIFACTS_RESOURCE_GROUP }}" \
              --name "$${IMAGE_SKU}-$${{ needs.latest_windows_version.outputs.version }}"; then
              image_exists=true
            else
              image_exists=false
            fi

            echo "Image Exists: $${image_exists}"
            echo "::set-output name=exists::$${image_exists}"

  packer:
    name: Run Packer
    runs-on: ubuntu-latest
    needs: [latest_windows_version, check_image_exists]
    if: needs.check_image_exists.outputs.exists == 'false'
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2

      - name: Validate Packer Template
        uses: hashicorp/packer-github-actions@master
        with:
          command: validate
          arguments: -syntax-only
          target: windows.pkr.hcl

      - name: Build Packer Image
        uses: hashicorp/packer-github-actions@master
        with:
          command: build
          arguments: -color=false -on-error=abort
          target: windows.pkr.hcl
        env:
          PKR_VAR_client_id: $${{ secrets.PACKER_CLIENT_ID }}
          PKR_VAR_client_secret: $${{ secrets.PACKER_CLIENT_SECRET }}
          PKR_VAR_subscription_id: $${{ secrets.PACKER_SUBSCRIPTION_ID }}
          PKR_VAR_tenant_id: $${{ secrets.PACKER_TENANT_ID }}
          PKR_VAR_artifacts_resource_group: $${{ secrets.PACKER_ARTIFACTS_RESOURCE_GROUP }}
          PKR_VAR_build_resource_group: $${{ secrets.PACKER_BUILD_RESOURCE_GROUP }}
          PKR_VAR_source_image_publisher: $${{ env.IMAGE_PUBLISHER }}
          PKR_VAR_source_image_offer: $${{ env.IMAGE_OFFER }}
          PKR_VAR_source_image_sku: $${{ env.IMAGE_SKU }}
          PKR_VAR_source_image_version: $${{ needs.latest_windows_version.outputs.version }}

  cleanup:
    name: Cleanup Packer Resources
    runs-on: ubuntu-latest
    needs: packer
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: $${{ secrets.AZURE_CREDENTIALS }}

      - name: Cleanup Resource Group
        uses: azure/CLI@v1
        with:
          azcliversion: 2.34.1
          inlineScript: |
            az deployment group create \
              --mode Complete \
              --resource-group "$${{ secrets.PACKER_BUILD_RESOURCE_GROUP }}" \
              --template-file cleanup-resource-group.bicep
EOT
  
  commit_message      = "Create packer_win11.yml"
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
