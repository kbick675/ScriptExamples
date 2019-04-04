provider "azurerm" {
  version = "=1.23.0"
}

terraform {
  backend "azurerm" {}
}

data "azurerm_resource_group" "IteResourceGroup" {
  name = "${var.IteResourceGroup}"
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "ResourceGroup" {
  name     = "Rg-${var.Number}"
  location = "${var.location}"

  tags {
    environment = "${var.environment}"
  }
}

data "azurerm_key_vault" "ITEKeyVault" {
  name                = "${var.IteKeyVaultName}"
  resource_group_name = "${data.azurerm_resource_group.IteResourceGroup.name}"
}

module "network" {
  source            = "./network"
  Number            = "${var.Number}"
  vNetSpace         = "${var.vNetSpace}"
  Subnet            = "${var.subnet}"
  ResourceGroupName = "${azurerm_resource_group.ResourceGroup.name}"
  location          = "${azurerm_resource_group.ResourceGroup.location}"
  environment       = "${var.environment}"
}

module "storage" {
  source = "./storage"

  #createStorage                             = true
  Number            = "${var.Number}"
  ResourceGroupName = "${azurerm_resource_group.ResourceGroup.name}"
  location          = "${azurerm_resource_group.ResourceGroup.location}"
  environment       = "${var.environment}"
}

module "sql" {
  source            = "./sql"
  Number            = "${var.Number}"
  ResourceGroupName = "${azurerm_resource_group.ResourceGroup.name}"
  iteKeyVaultId     = "${data.azurerm_key_vault.ITEKeyVault.id}"
  IteResourceGroup  = "${data.azurerm_resource_group.IteResourceGroup.name}"
  ResourceGroupName = "${azurerm_resource_group.ResourceGroup.name}"
  location          = "${azurerm_resource_group.ResourceGroup.location}"
  environment       = "${var.environment}"
  subnet_id         = "${module.network.subnet_id}"
  tenant_id         = "${data.azurerm_client_config.current.tenant_id}"
  object_id         = "${data.azurerm_client_config.current.service_principal_object_id}"
}

module "compute" {
  # NS
  source            = "./compute"
  environment       = "${var.environment}"
  Number            = "${var.Number}"
  vmSuffix          = "NS"
  VmSize            = "${var.VmSize}"
  VmSku             = "${var.VmSku}"
  count             = "${var.VmCount}"
  IteResourceGroup  = "${data.azurerm_resource_group.IteResourceGroup.name}"
  ResourceGroupName = "${azurerm_resource_group.ResourceGroup.name}"
  location          = "${azurerm_resource_group.ResourceGroup.location}"
  enableBootDiag    = true
  Storage           = "${module.storage.primary_blob_endpoint}"
  iteKeyVaultId     = "${data.azurerm_key_vault.ITEKeyVault.id}"
  dsc_endpoint      = "${var.dsc_endpoint}"
  dsc_key           = "${var.dsc_key}"
  nsg_id            = "${module.network.nsg_id}"
  subnet_id         = "${module.network.subnet_id}"
}
