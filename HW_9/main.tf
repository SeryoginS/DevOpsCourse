provider "azurerm" {
  features {}
  subscription_id = "9c9cc760-2c47-47e6-ae52-710d79695fa0"
}


# Створення групи ресурсів
resource "azurerm_resource_group" "rg" {
  name     = "terrafrom-${var.env_name}-resource-group"
  location = "Poland Central"
}

# Створення віртуальної мережі
resource "azurerm_virtual_network" "vnet" {
  name                = "terrafrom-${var.env_name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Створення підмережі 1
resource "azurerm_subnet" "subnet1" {
  name                 = "terrafrom-${var.env_name}-subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Створення підмережі 2
resource "azurerm_subnet" "subnet2" {
  name                 = "terrafrom-${var.env_name}-subnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Створення групи безпеки
resource "azurerm_network_security_group" "nsg" {
  name                = "terrafrom-${var.env_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

#web 
  security_rule {
    name                       = "WEB"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes    = var.allowed_ips
    destination_address_prefix = "*"
  }

#ssh 
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.allowed_ips
    destination_address_prefix = "*"
  }
}

# Асоціація підмережі 1 з групою безпеки
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association1" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Асоціація підмережі 1 з групою безпеки
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association2" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Налаштування публічної IP-адреси для обох машин
resource "azurerm_public_ip" "pip" {
  count               = 2
  name                = "terrafrom-${var.env_name}-pip-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Налаштування мережевого інтерфейсу для кожної машини
resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "terrafrom-${var.env_name}-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[count.index].id
  }
}

#Приватний ключ
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "key_hw9.pem"
}

# Створення віртуальних машин
resource "azurerm_linux_virtual_machine" "vm" {
  count                 = 2
  name                  = "terrafrom-lesson-vm-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  admin_password        = "lpBtu-Jy<X0?7(*,J!2D<djaDpa,"
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  disable_password_authentication = false
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Використання custom_data для встановлення веб-сервера та створення index.html
  custom_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              echo "<h1>Hostname: $(hostname)</h1>" > /var/www/html/index.html
              systemctl enable nginx
              systemctl start nginx
              EOF
            )
  tags = {
    environment = "testing"
  }
}
