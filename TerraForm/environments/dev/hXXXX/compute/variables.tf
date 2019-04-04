variable "environment" {}
variable "IteResourceGroup" {}
variable "ResourceGroupName" {}
variable "Number" {}
variable "vmSuffix" {}

variable "VmSize" {}
variable "VmSku" {}
variable "location" {}
variable "iteKeyVaultId" {}

variable "Storage" {}

variable "enableBootDiag" {
  default = true
}

variable "create_pip" {
  default = true
}

variable "count" {}
variable "dsc_endpoint" {}
variable "dsc_key" {}
variable "nsg_id" {}
variable "subnet_id" {}
