variable "environment" {
  type = "string"

  # dev, prod
  default = "dev"
}

variable "HospNumber" {
  type    = "string"
  default = "NNNN"
}

variable "ResourceGroupName" {
  type = "string"
}

variable "vNetSpace" {
  type    = "string"
  default = "10.0.0.0/16"
}

variable "Subnet" {
  type = "string"
}

variable "location" {
  type = "string"
}
