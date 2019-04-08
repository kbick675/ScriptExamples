resource "random_string" "vmLocalPassword" {
  length           = 21
  special          = true
  override_special = "!@*-"
}

resource "azurerm_key_vault_secret" "VmKeyVaultSecret" {
  name         = "${var.secretName}"
  value        = "${random_string.vmLocalPassword.result}"
  key_vault_id = "${var.keyVaultId}"

  tags {
    environment = "${var.environment}"
  }
}
