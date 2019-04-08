resource "azurerm_key_vault" "KeyVault" {
  name                            = "${var.Number}-KeyVault"
  location                        = "${var.location}"
  resource_group_name             = "${var.ResourceGroupName}"
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true

  sku {
    name = "standard"
  }

  tenant_id = "${var.tenant_id}"

  access_policy {
    tenant_id       = "${var.tenant_id}"
    object_id       = "${var.object_id}"
    key_permissions = []

    secret_permissions = [
      "backup",
      "delete",
      "get",
      "list",
      "purge",
      "recover",
      "restore",
      "set",
    ]
  }

  tags {
    environment = "${var.environment}"
  }
}
