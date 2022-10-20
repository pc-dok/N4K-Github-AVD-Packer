// NOTE: Create the Ressource Groups in Azure West Europe for the Azure Virtual Desktop Service

resource "azurerm_resource_group" "wvd" {
  name     = var.rg-wvd
  location = var.location
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypewvdrg
  }
}

// NOTE: Create WVD VNET with 3 Subnets

resource "azurerm_virtual_network" "wvd" {
  name                = var.vnet-wvd
  address_space       = var.wvd-addr-space
  location            = var.location
  resource_group_name = var.rg-wvd
  dns_servers         = var.dns-server-wvd
  depends_on          = [azurerm_resource_group.wvd]
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypewvdvnet
  }
}

resource "azurerm_subnet" "infrastructure" {
  name                 = "Infrastructure"
  resource_group_name  = var.rg-wvd
  virtual_network_name = azurerm_virtual_network.wvd.name
  address_prefixes     = var.wvd-adr-space-sn-infra
}

resource "azurerm_subnet" "wvd" {
  name                 = "wvd"
  resource_group_name  = var.rg-wvd
  virtual_network_name = azurerm_virtual_network.wvd.name
  address_prefixes     = var.wvd-adr-space-sn-wvd
}

//NOTE: Create NETWORK SECURITY GROUPS - NSG - RDP

resource "azurerm_network_security_group" "RDP" {
  name                = var.nsg-wvd
  location            = var.location
  resource_group_name = var.rg-wvd
  depends_on          = [azurerm_virtual_network.wvd]
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypewvdnsg
  }

  security_rule {
    name                       = "AllowSyncWithAzureAD"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureActiveDirectoryDomainServices"
    destination_address_prefix = "*"
  }

security_rule {
    name                       = "AllowPSRemoting"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = "AzureActiveDirectoryDomainServices"
    destination_address_prefix = "*"
  }

security_rule {
    name                       = "AllowRD"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "CorpNetSaw"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "infrastructure-nsg" {
  subnet_id                 = azurerm_subnet.infrastructure.id
  network_security_group_id = azurerm_network_security_group.RDP.id
  depends_on                = [azurerm_network_security_group.RDP]
}

resource "azurerm_subnet_network_security_group_association" "wvd-nsg" {
  subnet_id                 = azurerm_subnet.wvd.id
  network_security_group_id = azurerm_network_security_group.RDP.id
  depends_on                = [azurerm_network_security_group.RDP]
}

// NOTE: Create the peering between vnet main to vnet aadds in Azure West Europe

resource "azurerm_virtual_network_peering" "wvd-to-aadds" {
  name                         = var.vnet-peering-wvd-to-aadds
  resource_group_name          = var.rg-wvd
  virtual_network_name         = azurerm_virtual_network.wvd.name
  remote_virtual_network_id    = azurerm_virtual_network.aadds-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
  depends_on                   = [azurerm_virtual_network.wvd]
}

resource "azurerm_virtual_network_peering" "aadds-to-wvd" {
  name                         = var.vnet-peering-aadds-to-wvd
  resource_group_name          = var.rg
  virtual_network_name         = azurerm_virtual_network.aadds-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.wvd.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
  depends_on                   = [azurerm_virtual_network.aadds-vnet]
}

// NOTE: Create the Keyvault in Azure West Europe

# Create a KeyVault in Azure on my WVD RG

# Create KeyVault ID
resource "random_id" "kvname" {
  byte_length = 5
  prefix = var.kvprefix
}

# Keyvault Creation
data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "kv1" {
  depends_on                      = [azurerm_resource_group.wvd]
  name                            = random_id.kvname.hex
  location                        = var.location
  resource_group_name             = var.rg-wvd
  enabled_for_disk_encryption     = true
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days      = 7
  purge_protection_enabled        = false
  public_network_access_enabled   = true
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypekeyvault1
    }
  
  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey",
    ]

    secret_permissions = [
      "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set",
    ]

    certificate_permissions = [
      "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update",
    ]
    
    storage_permissions = [
      "Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update",
    ]
  }
}

# Create KeyVault VM passwords
resource "random_password" "dcadmin" {
  length = 20
  special = true
}

resource "random_password" "domainjoin" {
  length = 20
  special = true
}

resource "random_password" "localadminjh" {
  length = 20
  special = true
}

# Create Key Vault Secret
resource "azurerm_key_vault_secret" "dcadmin" {
  name          = var.dcadmin_secret
  value         = random_password.dcadmin.result
  key_vault_id  = azurerm_key_vault.kv1.id
  depends_on    = [ azurerm_key_vault.kv1 ]
}

resource "azurerm_key_vault_secret" "domainjoin" {
  name          = var.domainjoin_secret
  value         = random_password.domainjoin.result
  key_vault_id  = azurerm_key_vault.kv1.id
  depends_on    = [ azurerm_key_vault.kv1 ]
}


resource "azurerm_key_vault_secret" "localadminjh" {
  name          = var.localadminjh
  value         = random_password.localadminjh.result
  key_vault_id  = azurerm_key_vault.kv1.id
  depends_on    = [ azurerm_key_vault.kv1 ]
}

// NOTE: Create DomainJoin and DCAdmin User

resource "azuread_user" "dcadmin_user" {
  depends_on          = [azurerm_key_vault.kv1]
  user_principal_name = var.azuread-admin
  display_name        = "AADDS DC Admin"
  password            = azurerm_key_vault_secret.dcadmin.value
}

resource "azuread_user" "domainjoin_user" {
  depends_on          = [azurerm_key_vault.kv1]
  user_principal_name = var.azuread-domainjoin
  display_name        = "AADDS DomainJoin Admin"
  password            = azurerm_key_vault_secret.domainjoin.value
}

resource "azuread_group" "dc_admins" {
  depends_on       = [azurerm_key_vault.kv1]
  display_name     = "AAD DC Administrators"
  description      = "AADDS Administrators"
  members          = [azuread_user.dcadmin_user.object_id, azuread_user.domainjoin_user.object_id]
  security_enabled = true
}

// NOTE: Create a Bastion Env for the Jumping Host in the WVD Space

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.wvd.name
  virtual_network_name = azurerm_virtual_network.wvd.name
  address_prefixes     = var.subnet_bastion
  depends_on           = [azurerm_virtual_network.wvd]
}

resource "azurerm_public_ip" "bastion" {
  name                = var.pip_bastion
  location            = var.location
  resource_group_name = azurerm_resource_group.wvd.name
  allocation_method   = "Static"
  sku                 = "Standard"
  depends_on          = [azurerm_virtual_network.wvd]
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypepipbastion
  }
}

resource "azurerm_bastion_host" "bastion" {
  name                = var.bastion_name
  location            = var.location
  resource_group_name = azurerm_resource_group.wvd.name
  depends_on          = [azurerm_virtual_network.wvd]
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypebastion
    }
  
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

//NOTE: Create a Jumping Host for Testing AADDS

resource "azurerm_network_interface" "jh" {
  name                = var.nic_jh
  location            = azurerm_resource_group.wvd.location
  resource_group_name = azurerm_resource_group.wvd.name
  depends_on          = [azurerm_virtual_network.wvd]
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.wvd.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypenicjh
  }
}

# Import Data from the Packer Image
data "azurerm_image" "win2022" {
  name                = "2022-datacenter-20348.887.220806"
  resource_group_name = "n4k-we-packer-avd-images"
}


resource "azurerm_windows_virtual_machine" "jh" {
  name                = var.jh_name
  location            = var.location
  resource_group_name = azurerm_resource_group.wvd.name
  eviction_policy                 = "Deallocate"
  priority                        = "Spot"
  max_bid_price                   = 0.5
  size                  = var.vmsize
  admin_username        = var.jh_local_user
  admin_password        = azurerm_key_vault_secret.localadminjh.value
  network_interface_ids = [azurerm_network_interface.jh.id]
  depends_on            = [ azurerm_virtual_network.wvd,
                            azurerm_active_directory_domain_service.aadds,
                            azurerm_key_vault.kv1
                            ]
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypevmjh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.managed_disk_type
  }

  source_image_id = data.azurerm_image.win2022.id
  
  #source_image_reference {
  #  publisher = var.vm_publisher
  #  offer     = var.vm_offer
  #  sku       = var.vm_sku
  #  version   = var.vm_version
  #}
}

resource "azurerm_virtual_machine_extension" "jhdomainjoin" {
    name                 = "jhdomainjoin"
    virtual_machine_id   = azurerm_windows_virtual_machine.jh.id
    depends_on           = [azurerm_windows_virtual_machine.jh]
    publisher            = "Microsoft.Compute"
    type                 = "JsonADDomainExtension"
    type_handler_version = "1.0"
    auto_upgrade_minor_version = true
  
    settings = <<SETTINGS
      {
          "Name": "${var.wvd_domain}",
          "User": "${var.wvd_domain}\\${var.joinuser}",
          "Restart": "true",
          "Options": "3"
      }
  SETTINGS
  
    protected_settings = <<PROTECTED_SETTINGS
      {
          "Password": "${azurerm_key_vault_secret.domainjoin.value}"
      }
  PROTECTED_SETTINGS
  }

/*
resource "azurerm_virtual_machine_extension" "jh0" {
    name                 = "jh01"
    virtual_machine_id   = azurerm_windows_virtual_machine.jh.id
    depends_on           = [azurerm_virtual_machine_extension.jhdomainjoin]
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.0"
    auto_upgrade_minor_version = true
    settings             = <<SETTINGS
      {
          "fileUris": ["https://raw.githubusercontent.com/pc-dok/Azure-AFCE-Spinup-your-LAB/master/files/winrm2.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file winrm2.ps1"      
      }
  SETTINGS
}
*/
