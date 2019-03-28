data "azurerm_client_config" "current" {

}

resource "azurerm_key_vault" "HospKeyVault" {
    name                                    = "Hospital-${var.azHospNumber}-KeyVault"
    location                                = "${data.azurerm_resource_group.HospResourceGroup.location}"
    resource_group_name                     = "${data.azurerm_resource_group.HospResourceGroup.name}"
    enabled_for_deployment                  = true
    enabled_for_disk_encryption             = true
    enabled_for_template_deployment         = true

    sku {
        name                                = "standard"
    }

    tenant_id                               = "${data.azurerm_client_config.current.tenant_id}"

    access_policy {
        tenant_id                           = "${data.azurerm_client_config.current.tenant_id}"
        object_id                           = "${data.azurerm_client_config.current.service_principal_object_id}"
        key_permissions = [
        ]
        secret_permissions = [
            "backup",
            "delete",
            "get",
            "list",
            "purge",
            "recover",
            "restore",
            "set"
        ]
    }

    tags {
        environment             = "${var.environment}"
    }
}

resource "random_string" "vmLocalPassword" {
    length                              = 21
    special                             = true
    override_special                    = "!@*-" 
}
resource "azurerm_key_vault_secret" "HospVmKeyVaultSecret" {
    name                                = "test-localPassword"
    value                               = "${random_string.vmLocalPassword.result}"
    key_vault_id                        = "${azurerm_key_vault.HospKeyVault.id}"

    tags {
        environment                     = "${var.environment}"
    }
}
