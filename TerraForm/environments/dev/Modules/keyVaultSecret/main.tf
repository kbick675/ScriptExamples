resource "random_string" "random_string" {
  length           = 21
  special          = true
  override_special = "!@*-"
  count            = var.count
}

resource "azurerm_key_vault_secret" "KeyVaultSecret" {
  name         = var.secretName
  value        = random_string.random_string[count.index].result
  key_vault_id = var.keyVaultId
  count        = var.count

  tags = {
    environment = var.environment
  }
}

