variable "environment" {
    type = "string"
    # dev, prod
    default = "dev"
}
variable "ResourceGroup" {
    type = "string"
    default = "General-Rg-Dev"
}
variable "ResourceGroupName" {
    type = "string"
}
variable "HospNumber" {
    type = "string"
    default = "NNNN"
}
variable "vmSuffix" {
    type = "string"
}

variable "VmSize" {
    type = "string"
    # NS Server = "Standard_DS3_v2" DB Server = "Standard_E4s_v3"
    default = "Standard_DS3_v2"
}
variable "VmSku" {
    type = "string"
    # 2019-Datacenter, 2019-Datacenter-Core, 2016-Datacenter, 2016-Datacenter-Server-Core
    default = "2019-Datacenter" 
}
variable "location" {
    type = "string"
    # westcentralus, centralus, westus, westus2, eastus, eastus2, northcentralus, southcentralus, canadacentral, canadaeast
    default = "westus2"
}
variable "KeyVaultId" {
    type = "string"
}

variable "HospStorage" {
    type = "string"
}

variable "enableBootDiag" {
    default = true
}
variable "create_pip" {
    default = true
}
variable "count" { }

variable "dsc_endpoint" {
}
variable "dsc_key" {
}


