// NOTE: Create the Ressource Groups in Azure West Europe for the AADDS Service
resource "azurerm_resource_group" "main" {
  name     = var.rg
  location = var.location
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypeaadds
  }
}

// NOTE: Create vLAN Segment for Azure Active Directory Domain Services with 1 Subnet in Azure West Europe
resource "azurerm_virtual_network" "aadds-vnet" {
  name                = var.vnet-aadds
  address_space       = var.aadds-adr-space
  location            = var.location
  resource_group_name = var.rg
  dns_servers         = var.dns-server
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypeaaddsvnet
  }
  depends_on        = [azurerm_resource_group.main]
}

resource "azurerm_subnet" "aadds-sn" {
  name                      = var.sn-aadds
  resource_group_name       = var.rg
  virtual_network_name      = azurerm_virtual_network.aadds-vnet.name
  address_prefixes          = var.aadds-adr-space-sn
}

// NOTE: Create Network Security Group for Azure Active Directory Domain Services in Azure West Europe
resource "azurerm_network_security_group" "aadds-nsg" {
  name                = var.nsg-aadds
  location            = var.location
  resource_group_name = var.rg
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypeaaddsnsg
  }
  depends_on          = [azurerm_virtual_network.aadds-vnet]

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

resource "azurerm_subnet_network_security_group_association" "aadds-nsg-assoc" {
  subnet_id                 = azurerm_subnet.aadds-sn.id
  network_security_group_id = azurerm_network_security_group.aadds-nsg.id
  depends_on                = [azurerm_network_security_group.aadds-nsg]
}

// NOTE: Create Service Principal for aadds
// NOTE: If SPN is existing you can delete with: az ad sp delete --id "your id from the error message"

resource "azuread_service_principal" "aadds" {
  application_id = "2565bd9d-da50-47d4-8b85-4c97f669dc36"
}

// NOTE: Create the Azure Active Domain Directory Service 

resource "azurerm_active_directory_domain_service" "aadds" {
  name                = var.aadds-domain-name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  domain_name         = var.aadds-domain
  sku                 = var.aadds-sku
  tags = {
    "1_Info"  = var.taginfo
    "2_Type"  = var.tagtypeaaddsservice
  }

  initial_replica_set {
    subnet_id = azurerm_subnet.aadds-sn.id
  }

  notifications {
    additional_recipients = var.aadds-rc-mail
    notify_dc_admins      = true
    notify_global_admins  = true
  }

  security {
    sync_kerberos_passwords = true
    sync_ntlm_passwords     = true
    sync_on_prem_passwords  = true
  }

  depends_on = [
    azuread_service_principal.aadds,
    azurerm_subnet_network_security_group_association.aadds-nsg-assoc,
  ]
}
