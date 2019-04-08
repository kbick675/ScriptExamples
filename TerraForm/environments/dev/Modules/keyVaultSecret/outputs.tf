output "secretId" {
  value = "${azurerm_key_vault_secret.KeyVaultSecret.id}"
}

output "secretValue" {
  value = "${random_string.random_string.result}"
}
