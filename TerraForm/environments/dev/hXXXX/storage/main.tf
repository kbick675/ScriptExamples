resource "azurerm_storage_account" "HospStorage" {
    name                        = "${var.HospNumber}hospstorage"
    resource_group_name         = "${var.ResourceGroupName}"
    location                    = "${var.location}"
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags {
        environment             = "${var.environment}"
    }
}

output "primary_blob_endpoint" {
  value = "${azurerm_storage_account.HospStorage.primary_blob_endpoint}"
}
