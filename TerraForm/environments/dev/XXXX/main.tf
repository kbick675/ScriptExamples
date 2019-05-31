provider "azurerm" {
  version = "=1.29.0"
}

terraform {
  backend "azurerm" {}
}

module "ResourceGroup" {
  source      = "../Modules/resourceGroup"
  HospNumber  = "${var.HospNumber}"
  location    = "${var.location}"
  environment = "${var.environment}"
}

module "network" {
  source            = "../Modules/network"
  Number            = "${var.Number}"
  vNetSpace         = "${var.vNetSpace}"
  Subnet            = "${var.subnet}"
  ResourceGroupName = "${module.ResourceGroup.resourceGroupName}"
  location          = "${module.ResourceGroup.resourceGroupLocation}"
  environment       = "${var.environment}"
}

module "storage" {
  source = "../Modules/storage"

  #createStorage                             = true
  Number            = "${var.Number}"
  ResourceGroupName = "${module.ResourceGroup.resourceGroupName}"
  location          = "${module.ResourceGroup.resourceGroupLocation}"
  environment       = "${var.environment}"
}

module "sqlKeyVault" {
  source      = "../Modules/KeyVaultSecret"
  environment = "${var.environment}"
  secretName  = "${var.Number}SQLAdmin"
  keyVaultId  = "${data.azurerm_key_vault.ITEKeyVault.id}"
  count       = 1
}

module "sql" {
  source            = "../Modules/sql"
  Number            = "${var.Number}"
  iteKeyVaultId     = "${data.azurerm_key_vault.ITEKeyVault.id}"
  IteResourceGroup  = "${data.azurerm_resource_group.IteResourceGroup.name}"
  ResourceGroupName = "${module.ResourceGroup.resourceGroupName}"
  location          = "${module.ResourceGroup.resourceGroupLocation}"
  environment       = "${var.environment}"
  subnet_id         = "${module.network.subnet_id}"
  tenant_id         = "${data.azurerm_client_config.current.tenant_id}"
  object_id         = "${data.azurerm_client_config.current.service_principal_object_id}"
  sqlAdminPw        = "${module.sqlKeyVault.secretValue}"
}

module "compute" {
  # NS
  source            = "../Modules/compute"
  environment       = "${var.environment}"
  Number            = "${var.Number}"
  vmPrefix          = "RDS"
  vmSuffix          = "NS"
  VmSize            = "${var.VmSize}"
  VmSku             = "${var.VmSku}"
  count             = "${var.VmCount}"
  IteResourceGroup  = "${data.azurerm_resource_group.IteResourceGroup.name}"
  ResourceGroupName = "${module.ResourceGroup.resourceGroupName}"
  location          = "${module.ResourceGroup.resourceGroupLocation}"
  enableBootDiag    = true
  Storage           = "${module.storage.primary_blob_endpoint}"
  iteKeyVaultId     = "${data.azurerm_key_vault.ITEKeyVault.id}"
  dsc_endpoint      = "${var.dsc_endpoint}"
  dsc_key           = "${var.dsc_key}"
  nsg_id            = "${module.network.nsg_id}"
  subnet_id         = "${module.network.subnet_id}"
}
