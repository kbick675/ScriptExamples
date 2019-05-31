variable "environment" {}
variable "HospNumber" {}
variable "VmSize" {}
variable "VmCount" {}
variable "VmSku" {}
variable "IteResourceGroup" {}
variable "location" {}
variable "vNetSpace" {}
variable "subnet" {}
variable "IteKeyVaultName" {}
variable "dsc_endpoint" {}
variable "dsc_key" {}

## Data Sources
data "azurerm_resource_group" "IteResourceGroup" {
  name = "${var.IteResourceGroup}"
}

data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "ITEKeyVault" {
  name                = "${var.IteKeyVaultName}"
  resource_group_name = "${data.azurerm_resource_group.IteResourceGroup.name}"
}
