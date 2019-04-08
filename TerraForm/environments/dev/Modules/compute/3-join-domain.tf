data "azurerm_key_vault_secret" "tfdomainjoin" {
  name         = "tfdomainjoin"
  key_vault_id = "${var.iteKeyVaultId}"
}

resource "azurerm_virtual_machine_extension" "join-domain" {
  name                 = "joinDomain"
  location             = "${var.location}"
  resource_group_name  = "${var.ResourceGroupName}"
  virtual_machine_name = "${element(azurerm_virtual_machine.VM.*.name, count.index)}"
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  depends_on           = ["azurerm_virtual_machine.VM"]

  settings = <<BASESETTINGS
    {
        "Name": "domain.com",
        "OUPath": "",
        "User": "domain.com\tfdomainjoin",
        "Restart": "true",
        "Optio${var.vmSuffix}": "3"
    }
    BASESETTINGS

  protected_settings = <<PROTECTEDSETTINGS
    {
        "Password": "${data.azurerm_key_vault_secret.tfdomainjoin.value}"
    }
    PROTECTEDSETTINGS

  tags {
    environment = "${var.environment}"
  }
}
