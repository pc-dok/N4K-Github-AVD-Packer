// NOTE: Create the HostPool and Sessionhost for WVD

# Host Pool
resource "azurerm_virtual_desktop_host_pool" "avd" {
  name                = "avd-vdpool"
  location            = var.location
  resource_group_name = azurerm_resource_group.wvd.name
  type               = "Pooled"
  load_balancer_type = "BreadthFirst"
  friendly_name      = "AVD Host Pool using AADDS"
    tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypehostpool
  }
}

resource "time_rotating" "avd_registration_expiration" {
  # Must be between 1 hour and 30 days
  rotation_days = 29
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd.id
  expiration_date = time_rotating.avd_registration_expiration.rotation_rfc3339
}

# Workspace and App Group

resource "azurerm_virtual_desktop_workspace" "avd" {
  name                = "avd-vdws"
  location            = var.location
  resource_group_name = azurerm_resource_group.wvd.name
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypeworkspace
  }
}

resource "azurerm_virtual_desktop_application_group" "avd" {
  name                = "desktop-vdag"
  location            = var.location
  resource_group_name = azurerm_resource_group.wvd.name
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypevdag
    }
  type         = "Desktop"
  host_pool_id = azurerm_virtual_desktop_host_pool.avd.id
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "avd" {
  workspace_id         = azurerm_virtual_desktop_workspace.avd.id
  application_group_id = azurerm_virtual_desktop_application_group.avd.id
}

# Session Host VMs

resource "azurerm_network_interface" "avd" {
  count               = var.avd_host_pool_size
  name                = "avd-nic-${count.index}"
  location            = azurerm_resource_group.wvd.location
  resource_group_name = azurerm_resource_group.wvd.name
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypenicavd
    }

  ip_configuration {
    name                          = "avd-ipconf"
    subnet_id                     = azurerm_subnet.wvd.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Import Data from the Packer Image
data "azurerm_image" "win11" {
  name                = "win11-22h2-avd-22621.674.221008"
  resource_group_name = "n4k-we-packer-images"
}

resource "azurerm_windows_virtual_machine" "avd" {
  count               = var.avd_host_pool_size
  name                = "avd-vm-${count.index}" #-${random_id.avd[count.index].hex}
  location            = azurerm_resource_group.wvd.location
  resource_group_name = azurerm_resource_group.wvd.name
  #eviction_policy     = "Deallocate"
  #priority            = "Spot"
  #max_bid_price       = 0.5
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypevmavd
    }

  size                  = var.vmsizeavd
  license_type          = "Windows_Client" # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/windows-desktop-multitenant-hosting-deployment#verify-your-vm-is-utilizing-the-licensing-benefit
  admin_username        = var.jh_local_user
  admin_password        = azurerm_key_vault_secret.localadminjh.value
  network_interface_ids = [azurerm_network_interface.avd[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.managed_disk_type_avd
  }

  source_image_id = data.azurerm_image.win11.id

  #source_image_reference {
  #  publisher = var.vm_publisher_avd
  #  offer     = var.vm_offer_avd
  #  sku       = var.vm_sku_avd
  #  version   = var.vm_version_avd
  #}
}

# AADDS Domain-join

resource "azurerm_virtual_machine_extension" "avd_aadds_join" {
  count                      = length(azurerm_windows_virtual_machine.avd)
  name                       = "aadds-join-vmext"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "Name": "${var.wvd_domain}",
      "OUPath": "${var.avd_ou_path}",
      "User": "${var.wvd_domain}\\${var.joinuser}",
      "Restart": "true",
      "Options": "3"
    }
    SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
    {
      "Password": "${azurerm_key_vault_secret.domainjoin.value}"
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [
    azurerm_virtual_network_peering.wvd-to-aadds,
    azurerm_virtual_network_peering.aadds-to-wvd
  ]
}

# Register to Host Pool

resource "azurerm_virtual_machine_extension" "avd_register_session_host" {
  count                = length(azurerm_windows_virtual_machine.avd)
  name                 = "register-session-host-vmext"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd[count.index].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.73"

  settings = <<-SETTINGS
    {
      "modulesUrl": "${var.avd_register_session_host_dsc_modules_url}",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "hostPoolName": "${azurerm_virtual_desktop_host_pool.avd.name}",
        "aadJoin": false
      }
    }
    SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
    {
      "properties": {
        "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.avd.token}"
      }
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [azurerm_virtual_machine_extension.avd_aadds_join]
}

# Role-based Access Control

data "azurerm_role_definition" "desktop_virtualization_user" {
  name = "Desktop Virtualization User"
}

# Create KeyVault AVD User passwords
resource "random_password" "avduser" {
  length = 20
  special = true
}

# Create Key Vault Secret
resource "azurerm_key_vault_secret" "avduser" {
  name          = var.avduser
  value         = random_password.avduser.result
  key_vault_id  = azurerm_key_vault.kv1.id
  depends_on    = [ azurerm_key_vault.kv1 ]
}

# Create 2 AVD Testusers in AADDS
resource "azuread_user" "avduser1" {
  depends_on          = [azurerm_key_vault.kv1]
  user_principal_name = var.avduser1
  display_name        = "AVD Test User 1"
  password            = azurerm_key_vault_secret.avduser.value
}

resource "azuread_user" "avduser2" {
  depends_on          = [azurerm_key_vault.kv1]
  user_principal_name = var.avduser2
  display_name        = "AVD Test User 2"
  password            = azurerm_key_vault_secret.avduser.value
}

resource "azuread_group" "avd_users" {
  display_name     = "AVD Users"
  description      = "AVD Test User Group"
  members          = [azuread_user.avduser1.object_id, azuread_user.avduser2.object_id]
  security_enabled = true
}

resource "azurerm_role_assignment" "avd_users_desktop_virtualization_user" {
  scope                 = azurerm_virtual_desktop_application_group.avd.id
  role_definition_name  = data.azurerm_role_definition.desktop_virtualization_user.name
  principal_id          = azuread_group.avd_users.id
}

/*
resource "azurerm_virtual_machine_extension" "avdsoftware" {
    count                = length(azurerm_windows_virtual_machine.avd)
    name                 = "avdsoftware"
    virtual_machine_id   = azurerm_windows_virtual_machine.avd[count.index].id
    depends_on           = [azurerm_virtual_machine_extension.avd_register_session_host]
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.0"
    auto_upgrade_minor_version = true
    settings             = <<SETTINGS
      {
          "fileUris": ["https://raw.githubusercontent.com/pc-dok/Azure-AFCE-Spinup-your-LAB/master/files/avd.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file avd.ps1"      
      }
  SETTINGS
}
*/
