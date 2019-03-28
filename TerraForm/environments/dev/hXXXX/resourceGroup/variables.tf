variable "environment" {
    type = "string"
    # dev, prod
    default = "dev"
}
variable "HospNumber" {
    type = "string"
    default = "NNNN"
}
variable "location" {
    type = "string"
    # westcentralus, centralus, westus, westus2, eastus, eastus2, northcentralus, southcentralus, canadacentral, canadaeast
    default = "westus2"
}

