# Terraform Cloud Variables - Please ensure RBAC Contributer Settings in this Variables

variable "ARM_CLIENT_ID" {}
variable "ARM_CLIENT_SECRET" {}
variable "ARM_TENANT_ID" {}
variable "ARM_SUBSCRIPTION" {}
variable "GITHUB_SECRET" {}
variable "GITHUB_OWNER" {}

# My Azure Admin User for administrate than Keyvault
variable "aduser-info" {
  type        = string
  default     = "info@network4kmu.at"
}

# Tags 
variable "taginfo" {
  type        = string
  default     = "N4K-IT-Infrastructure"
}

variable "tagtypeaadds" {
  type        = string
  default     = "RG for AADDS"
}

variable "tagtypeaaddsvnet" {
  type        = string
  default     = "VNET for AADDS"
}

variable "tagtypeaaddsnsg" {
  type        = string
  default     = "NSG for AADDS"
}

variable "tagtypeaaddsservice" {
  type        = string
  default     = "N4K AADDS - n4k-at"
}

variable "tagtypewvdrg" {
  type        = string
  default     = "RG for WVD"
}

variable "tagtypewvdvnet" {
  type        = string
  default     = "VNET for WVD"
}

variable "tagtypewvdnsg" {
  type        = string
  default     = "NSG for WVD"
}

variable "tagtypebastion" {
  type        = string
  default     = "Bastion for WVD"
}

variable "tagtypepipbastion" {
  type        = string
  default     = "Bastion PIP for WVD"
}

variable "tagtypenicjh" {
  type        = string
  default     = "NIC for JH VM"
}

variable "tagtypevmjh" {
  type        = string
  default     = "VM JH"
}

variable "tagtypehostpool" {
  type        = string
  default     = "AVD HostPool N4K"
}

variable "tagtypevdag" {
  type        = string
  default     = "AVD Application Group"
}

variable "tagtypenicavd" {
  type        = string
  default     = "NIC for AVD Desktops"
}

variable "tagtypevmavd" {
  type        = string
  default     = "Desktop VMs AVD N4K"
}

variable "tagtypeworkspace" {
  type        = string
  default     = "Workspace AVD N4K"
}

variable "tagtypekeyvault1" {
  type        = string
  default     = "Keyvault for WVD N4K"
}

# Main
variable "rg" {
  type        = string
  default     = "n4k-we-aadds"
  description = "Ressoure Group for N4K-LAB"
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "The location from Azure Ressource"
}

variable "kv1" {
  type        = string
  default     = "n4kwekv1fortheazwvdenv"
  description = "The KeyVault Name"
}

variable "vnet-aadds" {
  type        = string
  default     = "vnet-we-aadds"
  description = "vnet for the AADDS Service"
}

variable "aadds-adr-space" {
  type        = list
  default     = ["10.0.0.0/16"]
  description = "Adress Space for the AADDS Service"
}

variable "dns-server" {
  type        = list
  default     = ["10.0.0.4", "10.0.0.5"]
  description = "DNS Server for the AADDS vnet"
}

variable "sn-aadds" {
  type        = string
  default     = "sn-we-aadds"
  description = "subnet for the AADDS Service"
}

variable "aadds-adr-space-sn" {
  type        = list
  default     = ["10.0.0.0/24"]
  description = "Adress Subnet Space for the AADDS Service"
}

variable "nsg-aadds" {
  type        = string
  default     = "nsg-we-aadds"
  description = "NSG for the AADDS Service"
}

variable "azuread-admin" {
  type        = string
  default     = "dcadmin@n4k.at"
  description = "AADDS Admin User for the AADDS Service"
}

variable "azuread-domainjoin" {
  type        = string
  default     = "domainjoin@n4k.at"
  description = "AADDS Domain Join User for the AADDS Service"
}

variable "aadds-domain-name" {
  type        = string
  default     = "aadds-n4k-at"
  description = "The Name of the AADDS Service"
}

variable "aadds-domain" {
  type        = string
  default     = "n4k.at"
  description = "The Domain of AADDS in Ressource Group"
}

variable "aadds-rc-mail" {
  type        = list
  default     = ["info@n4k.at"]
  description = "The Notification Recipient of AADDS in Ressource Group"
}

variable "aadds-sku" {
  type        = string
  default     = "Standard"
  description = "SKU for the AADDS"
}

# WVD

variable "vnet-wvd" {
  type        = string
  default     = "vnet-we-wvd"
  description = "vnet for the Azure Virtual Desktop Service"
}

variable "wvd-addr-space" {
  type        = list
  default     = ["10.1.0.0/16"]
  description = "Adress Space for the Azure Virtual Desktop Service"
}

variable "rg-wvd" {
  type        = string
  default     = "n4k-we-wvd"
  description = "Ressoure Group for WVD"
}

variable "dns-server-wvd" {
  type        = list
  default     = ["10.0.0.4", "10.0.0.5", "8.8.8.8"]
  description = "DNS Server for the WVD vnet"
}

variable "wvd-adr-space-sn-infra" {
  type        = list
  default     = ["10.1.1.0/24"]
  description = "Adress Subnet Space for the WVD Infrastructure"
}

variable "wvd-adr-space-sn-wvd" {
  type        = list
  default     = ["10.1.2.0/24"]
  description = "Adress Subnet Space for the WVD Clients"
}

variable "nsg-wvd" {
  type        = string
  default     = "nsg-we-wvd"
  description = "NSG for the Azure Virtual Desktop Service"
}

variable "jh_osdisk" {
  type        = string
  default     = "jh-01-osdisk"
  description = "OS Disc Name JH"
}

variable "vmsize" {
  type        = string
  default     = "Standard_D4s_v4"
  description = "VM Size"
}

variable "vmsizeavd" {
  type        = string
  default     = "Standard_D4s_v4"
  description = "VM Size"
}

variable "vm_publisher" {
  type        = string
  default     = "MicrosoftWindowsServer"
  description = "Publisher OS Type"
}

variable "vm_offer" {
  type        = string
  default     = "WindowsServer"
  description = "Offer OS Type"
}
variable "vm_sku" {
  type        = string
  default     = "2019-Datacenter"
  description = "OS Server Version"
}

variable "vm_version" {
  type        = string
  default     = "latest"
  description = "OS Server Version Type"
}

variable "vm_publisher_avd" {
  type        = string
  default     = "MicrosoftWindowsDesktop"
  description = "Desktop Publisher OS Type"
}

variable "vm_offer_avd" {
  type        = string
  default     = "windows-11"
  description = "Desktop Offer OS Type"
}
variable "vm_sku_avd" {
  type        = string
  default     = "win11-21h2-avd"
  description = "OS Desktop Version"
}

variable "vm_version_avd" {
  type        = string
  default     = "latest"
  description = "OS Desktop Version Type"
}

variable "managed_disk_type" {
  type        = string
  default     = "Standard_LRS"
  description = "OS Disc Type"
}

variable "managed_disk_type_avd" {
  type        = string
  default     = "Premium_LRS"
  description = "OS Disc Type"
}

variable "jh_name" {
  type        = string
  default     = "jh-01"
  description = "VM Name of Jumping Host"
}

variable "jh_local_user" {
  type        = string
  default     = "localadmin"
  description = "VM Local Admin User Name"
}

variable "nic_jh" {
  type        = string
  default     = "jh-01-nic"
  description = "VM nic name of JH"
}

variable "subnet_bastion" {
  type        = list
  default     = ["10.1.3.0/26"]
  description = "Adress Subnet Space for the WVD Bastion Host"
}

variable "pip_bastion" {
  type        = string
  default     = "pip-bastion"
  description = "Public IP for Bastion"
}

variable "bastion_name" {
  type        = string
  default     = "Bastion-WVD"
  description = "Bastion Name for WVD"
}

variable "avd_ou_path" {
  type        = string
  description = "OU path used to AADDS domain-join AVD session hosts."
  default     = ""
}

variable "kvprefix" {
  type        = string
  description = "Key Vault Prefix Name"
  default     = "kvn4kwvd"
}

variable "domainjoin_secret" {
  type        = string
  description = "Key Vault Name DomainJoin"
  default     = "domainjoin"
}

variable "dcadmin_secret" {
  type        = string
  description = "Key Vault Name DCAdmin"
  default     = "dcadmin"
}

variable "localadminjh" {
  type        = string
  description = "Key Vault Name Local ADM for JH"
  default     = "localadminJH"
}

variable "wvd_domain" {
  type        = string
  description = "WVD Domain"
  default     = "n4k.at"
}

variable "joinuser" {
  type        = string
  description = "WVD Domain Join User"
  default     = "domainjoin"
}

variable "avd_host_pool_size" {
  type        = number
  description = "Number of session hosts to add to the AVD host pool."
  default     = "1"
}

variable "avd_register_session_host_dsc_modules_url" {
  type        = string
  description = "URL to .zip file containing DSC configuration to register AVD session hosts to AVD host pool."
  # Get list of releases used by Azure Portal
  # https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts?restype=container&comp=list&prefix=Configuration
  # Development version from master branch
  # https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip
  default = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_02-23-2022.zip"
}

variable "avd_user_upns" {
  type        = list(string)
  description = "List of user UPNs authorized to access AVD."
  default     = [ "avduser1@n4k.at", "avduser2@n4k.at" ]
}

variable "avduser" {
  type        = string
  description = "Keyvault AVD User Name"
  default     = "avduser"
}

variable "avduser1" {
  type        = string
  description = "AVD Test User 1"
  default     = "avduser1@n4k.at"
}

variable "avduser2" {
  type        = string
  description = "AVD Test User 2"
  default     = "avduser2@n4k.at"
}

# Peering vnets
variable "vnet-peering-wvd-to-aadds" {
  type        = string
  default     = "vnet-peering-wvd-to-aadds"
  description = "The vnet Peering from WVD to AADDS"
}

variable "vnet-peering-aadds-to-wvd" {
  type        = string
  default     = "vnet-peering-aadds-to-n4k"
  description = "The vnet Peering from AADDS to WVD"
}
