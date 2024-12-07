provider "azurerm" {
  features {}
  subscription_id = "6b56c47e-45f7-4ef7-912c-e2f6ee545e78" # Replace with your actual Subscription ID
}

# Generate SSH Key
resource "tls_private_key" "Anuragkey" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Resource Group
resource "azurerm_resource_group" "Anuragrg" {
  name     = "Anuragrg-resources"
  location = "UK South"
}

# Virtual Network
resource "azurerm_virtual_network" "Anuragvn" {
  name                = "Anuragvn-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.Anuragrg.location
  resource_group_name = azurerm_resource_group.Anuragrg.name
}

# Subnet
resource "azurerm_subnet" "Anuragsn" {
  name                 = "Anuragsn-subnet"
  resource_group_name  = azurerm_resource_group.Anuragrg.name
  virtual_network_name = azurerm_virtual_network.Anuragvn.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "Anuragpi" {
  name                = "Anuragpi-pip"
  location            = azurerm_resource_group.Anuragrg.location
  resource_group_name = azurerm_resource_group.Anuragrg.name
  allocation_method   = "Static"
}

# Network Interface
resource "azurerm_network_interface" "Anuragni" {
  name                = "Anuragni-nic"
  location            = azurerm_resource_group.Anuragrg.location
  resource_group_name = azurerm_resource_group.Anuragrg.name

  ip_configuration {
    name                          = "Anuragic-ipconfig"
    subnet_id                     = azurerm_subnet.Anuragsn.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Anuragpi.id
  }
}

# Managed Disk
resource "azurerm_managed_disk" "Demovm_disk" {
  name                 = "Demo-disk"
  resource_group_name  = azurerm_resource_group.Anuragrg.name
  location             = azurerm_resource_group.Anuragrg.location
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 10
  create_option        = "Empty"
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "Anuragvm" {
  name                = "Demovm-vm"
  resource_group_name = azurerm_resource_group.Anuragrg.name
  location            = azurerm_resource_group.Anuragrg.location
  size                = "Standard_B1s"
  admin_username      = "AnuragAzure"
  network_interface_ids = [
    azurerm_network_interface.Anuragni.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.boot_diag_Demovm-vm_sa.primary_blob_endpoint
  }

  admin_ssh_key {
    username   = "AnuragAzure"
    public_key = tls_private_key.Anuragkey.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Data Disk Attachment
resource "azurerm_virtual_machine_data_disk_attachment" "Demovm_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.Demovm_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.Anuragvm.id
  lun                = 0 # Logical Unit Number
  caching            = "ReadWrite"
}

# enable boot diag for vm
resource "azurerm_storage_account" "boot_diag_Demovm-vm_sa" {
  name = "demovmdiag" # Must be globally unique
  resource_group_name      = azurerm_resource_group.Anuragrg.name
  location                 = azurerm_resource_group.Anuragrg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
# Output the public IP of the VM
output "public_ip" {
  value = azurerm_public_ip.Anuragpi.ip_address
}
