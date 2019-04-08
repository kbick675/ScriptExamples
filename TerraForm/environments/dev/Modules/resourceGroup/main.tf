resource "azurerm_resource_group" "ResourceGroup" {
  name     = "Rg-${var.Number}"
  location = "${var.location}"

  tags {
    environment = "${var.environment}"
  }
}
