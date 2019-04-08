output "vnet_id" {
  value = "${azurerm_virtual_network.virtualNetwork.id}"
}

output "subnet_id" {
  value = "${azurerm_subnet.Subnet.id}"
}

output "nsg_id" {
  value = "${azurerm_network_security_group.nsg.id}"
}