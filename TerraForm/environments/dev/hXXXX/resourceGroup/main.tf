provider "azurerm" {
    version                     = "=1.23.0"
}

resource "azurerm_resource_group" "HospResourceGroup" {
    name                        = "HospRg-${var.HospNumber}"
    location                    = "${var.location}"

    tags {
        environment             = "${var.environment}"
    }
}




