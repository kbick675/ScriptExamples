provider "azurerm" {
    version                                 = "=1.23.0"
}

terraform {
    backend "azurerm" {
    }
}

data "azurerm_resource_group" "ResourceGroup" {
    name                        = "${var.ResourceGroup}"             
}

data "azurerm_client_config" "current" {

}

resource "azurerm_resource_group" "HospResourceGroup" {
    name                        = "HospRg-${var.HospNumber}"
    location                    = "${var.location}"

    tags {
        environment             = "${var.environment}"
    }
}

data "azurerm_key_vault" "KeyVault" {
    name                                = "${var.KeyVaultName}"
    resource_group_name                 = "${data.azurerm_resource_group.ResourceGroup.name}"
}

module "network" {
  source                                    = "./network"
  HospNumber                                = "${var.HospNumber}"
  vNetSpace                                 = "${var.vNetSpace}"
  Subnet                                    = "${var.subnet}"
  ResourceGroupName                         = "${azurerm_resource_group.HospResourceGroup.name}"
  location                                  = "${azurerm_resource_group.HospResourceGroup.location}"
  environment                               = "${var.environment}"         
}

module "storage" {
  source                                    = "./storage"
  #createStorage                             = true
  HospNumber                                = "${var.HospNumber}"
  ResourceGroupName                         = "${azurerm_resource_group.HospResourceGroup.name}"
  location                                  = "${azurerm_resource_group.HospResourceGroup.location}"
  environment                               = "${var.environment}"
}

module "sql" {
  source                                    = "./sql"
  HospNumber                                = "${var.HospNumber}"
  ResourceGroupName                         = "${azurerm_resource_group.HospResourceGroup.name}"
  KeyVaultId                             = "${data.azurerm_key_vault.KeyVault.id}"
  ResourceGroup                          = "${data.azurerm_resource_group.ResourceGroup.name}"
  ResourceGroupName                         = "${azurerm_resource_group.HospResourceGroup.name}"
  location                                  = "${azurerm_resource_group.HospResourceGroup.location}"
  environment                               = "${var.environment}"
}


module "compute" {
  # NS
  source                                    = "./compute"
  environment                               = "${var.environment}"
  HospNumber                                = "${var.HospNumber}"
  vmSuffix                                  = "NS"
  VmSize                                    = "${var.VmSize}"
  VmSku                                     = "${var.VmSku}"
  count                                     = "${var.VmCount}"
  ResourceGroup                          = "${data.azurerm_resource_group.ResourceGroup.name}"
  ResourceGroupName                         = "${azurerm_resource_group.HospResourceGroup.name}"
  location                                  = "${azurerm_resource_group.HospResourceGroup.location}"
  enableBootDiag                            = true
  HospStorage                               = "${module.storage.primary_blob_endpoint}"
  KeyVaultId                             = "${data.azurerm_key_vault.KeyVault.id}"
  dsc_endpoint                              = "${var.dsc_endpoint}"
  dsc_key                                   = "${var.dsc_key}"
}

