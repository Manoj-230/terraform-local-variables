terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
    features {}
  
}

locals {
  security = azurerm_subnet_network_security_group_association.nsg_subnet_assoc.network_security_group_id
}
data "azurerm_resource_group" "rg1" {
  name = "Nextopsvideos1"
}

output "id" {
  value = data.azurerm_resource_group.rg1.id
}

locals {
  rg_info = data.azurerm_resource_group.rg1
}

data "azurerm_virtual_network" "vnet1" {
  name                = "Nextopsvnet1"
  resource_group_name = local.rg_info.name
}

data "azurerm_subnet" "subnet1" {
  name                 = "subnet01"
  resource_group_name  = local.rg_info.name
  virtual_network_name = data.azurerm_virtual_network.vnet1.name
}

data "azurerm_network_security_group" "nsg1" {
  name                = "Nextops-nsg1"
  resource_group_name = azurerm_resource_group.Nextops-nsg1.name
}

output "location" {
  value = data.azurerm_network_security_group.Nextops-nsg1.location
}

resource "azurerm_network_security_rule" "rdp" {
  name                        = "rdp"
  resource_group_name         = "${local.rg_info.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg1.name}"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc" {
  subnet_id                     = data.azurerm_subnet.subnet1.id
  network_security_group_id     = azurerm_network_security_group.nsg1.id
}

resource "azurerm_network_interface" "nic1" {
  name                    = "Nextopsvm-nic"
  resource_group_name     = local.rg_info.name
  location                = data.azurerm_resource_group.rg1.location

  ip_configuration {
     name                          = "internal"
     subnet_id                     = data.azurerm_subnet.subnet1.id
     private_ip_address_allocation = "Dynamic"
  }
}
  
resource "azurerm_virtual_machine" "main" {
  name                    = "Nextopsvm"
  resource_group_name     = local.rg_info.name
  location                = data.azurerm_resource_group.rg1.location
  vm_size                 = "Standard_B1s"
  network_interface_ids   = [ azurerm_network_interface.nic1.id ]
  
  storage_image_reference {
    publisher = "Microsoftwindowsserver"
    offer     = "windowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

 os_profile {
    computer_name  = "hostname"
    admin_username = "adminuser"
  }

  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      path     = "/home/adminuser/.ssh/authorized_keys"
      key_data = "SSH_PUBLIC_KEY"
    }
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
}


  