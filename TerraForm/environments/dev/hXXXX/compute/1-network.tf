provider "azurerm" {
    version                             = "=1.23.0"
}

data "azurerm_network_security_group" "HospNsg" {
    name                                = "${var.HospNumber}-NSG"
    resource_group_name                 = "${var.ResourceGroupName}"   
}

data "azurerm_subnet" "HospSubnet" {
    name                                = "${var.HospNumber}-Subnet"
    virtual_network_name                = "${var.HospNumber}-vNet"
    resource_group_name                 = "${var.ResourceGroupName}" 
}

/* 
    resource "azurerm_public_ip" "HospPublicIp" {
    #create_pip                          = "${var.create_pip}"
    name                                = "h${var.HospNumber}-${var.vmSuffix}${1 + count.index}-ext"
    location                            = "${data.azurerm_resource_group.HospResourceGroup.location}"
    resource_group_name                 = "${data.azurerm_resource_group.HospResourceGroup.name}"
    allocation_method                   = "Dynamic"
    count                               = "${var.count}"

    tags {
        environment                     = "${var.environment}"
    }
}
*/

resource "azurerm_network_interface" "HospNic" {
    name                                = "h${var.HospNumber}-${var.vmSuffix}${1 + count.index}-int"
    location                            = "${var.location}"
    resource_group_name                 = "${var.ResourceGroupName}"
    internal_dns_name_label             = "h${var.HospNumber}-${var.vmSuffix}${1 + count.index}"
    network_security_group_id           = "${data.azurerm_network_security_group.HospNsg.id}"
    count                               = "${var.count}"

    ip_configuration {
        name                            = "primary"
        subnet_id                       = "${data.azurerm_subnet.HospSubnet.id}"
        private_ip_address_allocation   = "Dynamic"
        #private_ip_address_allocation   = "static"
        #private_ip_address              = "10.0.2.${1 + count.index}" # If we choose to do Static
        #public_ip_address_id            = "${azurerm_public_ip.HospPublicIp.id}" # would we ever have a public IP?
    }

    tags {
        environment                     = "${var.environment}"
    }
}