resource "azurerm_storage_account" "Storage" {
  name                     = "${var.Number}storage"
  resource_group_name      = var.ResourceGroupName
  location                 = var.location
  account_replication_type = "LRS"
  account_tier             = "Standard"

  tags = {
    environment = var.environment
  }
}

