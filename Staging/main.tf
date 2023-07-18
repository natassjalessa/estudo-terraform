terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.64"
    }
  }
}

provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name = "rg-tae-iac"
    storage_account_name = "terraform-script"
    container_name = "tfstate"
    key = "staging.terraform.tfstate"
  }
}

#Resource Group
resource "azurerm_resource_group" "default" {
  name = "rg-tae-iac"
  location = var.location
}

#Virtual Network 
resource "azurerm_virtual_network" "default" {
  name = "vnet-tae-iac"
  address_space = ["10.0.0.0/16"]
  location = var.location
  resource_group_name = var.rg
}

#Subnet
resource "azurerm_subnet" "internal" {
  name = "internal"
  resource_group_name = var.rg
  virtual_network_name = var.vnet
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "default" {
  name                = "${var.vm}-ip"
  resource_group_name = var.rg
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "default" {
  name                = "${var.vm}-nsg"
  resource_group_name = var.rg
  location            = var.location

  security_rule {
    name                       = "SSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


#Interface Rede
resource "azurerm_network_interface" "default" {
  name                = "${var.vm}-nic"
  location            = var.location
  resource_group_name = var.rg

  ip_configuration {
    name                          = "${var.vm}-ipconfig"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Virtual Machine
resource "azurerm_virtual_machine" "main" {
  name                  = "${var.vm}01"
  location              = var.location
  resource_group_name   = var.rg
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.vm}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.vm
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}