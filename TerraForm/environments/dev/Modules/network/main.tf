provider "azurerm" {
  version = "=1.23.0"
}

data "azurerm_resource_group" "HospResourceGroup" {
  name = "${var.ResourceGroupName}"
}

resource "azurerm_virtual_network" "HospNetwork" {
  name                = "${var.HospNumber}-vNet"   # Not entirely sure how I want to handle the vNet
  address_space       = ["${var.vNetSpace}"]
  location            = "${var.location}"
  resource_group_name = "${var.ResourceGroupName}"

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_subnet" "HospSubnet" {
  name                 = "${var.HospNumber}-Subnet"
  resource_group_name  = "${var.ResourceGroupName}"
  virtual_network_name = "${azurerm_virtual_network.HospNetwork.name}"
  address_prefix       = "${var.Subnet}"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.HospNumber}-NSG"
  location            = "${var.location}"
  resource_group_name = "${var.ResourceGroupName}"

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_network_security_rule" "RDP" {
  name                        = "${var.HospNumber}-RDP-in"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.ResourceGroupName}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "WinRMHTTPS" {
  name                        = "${var.HospNumber}-WinRMHTTPS-in"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5986"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.ResourceGroupName}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}
