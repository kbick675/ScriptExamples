output "secretId" {
  value = "${azurerm_key_vault_secret.VmKeyVaultSecret.id}"
}

output "secretVersion" {
  value = "${azurerm_key_vault_secret.VmKeyVaultSecret.version}"
}
