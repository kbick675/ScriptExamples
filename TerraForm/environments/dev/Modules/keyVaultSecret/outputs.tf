output "secretId" {
  value = azurerm_key_vault_secret.KeyVaultSecret[0].id
}

output "secretValue" {
  value = random_string.random_string[0].result
}

