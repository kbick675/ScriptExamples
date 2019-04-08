resource "azurerm_network_security_group" "nsg" {
  name                = "${var.HospNumber}-NSG"
  location            = "${var.location}"
  resource_group_name = "${var.ResourceGroupName}"

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_ddos_protection_plan" "ddosplan" {
  name                = "${var.HospNumber}-ddosplan"
  location            = "${var.location}"
  resource_group_name = "${var.ResourceGroupName}"
}

resource "azurerm_virtual_network" "virtualNetwork" {
  name                = "${var.HospNumber}-vNet"  
  address_space       = ["${var.vNetSpace}"]
  location            = "${var.location}"
  resource_group_name = "${var.ResourceGroupName}"

  ddos_protection_plan {
    id     = "${azurerm_ddos_protection_plan.ddosplan.id}"
    enable = true
  }
  
  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_subnet" "Subnet" {
  name                 = "${var.Number}-Subnet"
  resource_group_name  = "${var.ResourceGroupName}"
  virtual_network_name = "${azurerm_virtual_network.virtualNetwork.name}"
  address_prefix       = "${var.Subnet}"
}


resource "azurerm_network_security_rule" "RDP" {
  name                        = "${var.Number}-RDP-in"
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
