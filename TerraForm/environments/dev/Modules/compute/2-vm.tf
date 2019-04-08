resource "random_string" "vmLocalPassword" {
  length           = 21
  special          = true
  override_special = "!@*-"
  count            = "${var.count}"
}

resource "azurerm_key_vault_secret" "VmKeyVaultSecret" {
  name         = "${var.vmPrefix}${var.Number}-${var.vmSuffix}${1 + count.index}localPassword"
  value        = "${random_string.vmLocalPassword.*.result[count.index]}"
  key_vault_id = "${var.iteKeyVaultId}"
  count        = "${var.count}"

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_virtual_machine" "VM" {
  name                             = "${var.vmPrefix}${var.Number}-${var.vmSuffix}${1 + count.index}"
  location                         = "${var.location}"
  resource_group_name              = "${var.IteResourceGroup}"
  network_interface_ids            = ["${element(azurerm_network_interface.Nic.*.id, count.index)}"]
  vm_size                          = "${var.VmSize}"
  delete_data_disks_on_termination = true
  delete_os_disk_on_termination    = true
  count                            = "${var.count}"

  storage_os_disk {
    name              = "${var.vmPrefix}${var.Number}-${var.vmSuffix}${1 + count.index}-OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "${var.VmSku}"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.vmPrefix}${var.Number}-${var.vmSuffix}${1 + count.index}"
    admin_username = "azureadmin"
    admin_password = "${element(azurerm_key_vault_secret.VmKeyVaultSecret.*.value, count.index)}"
  }

  /*
  os_profile_secrets {
      vault_certificates {
          certificate_url             = "${var.certificate_url}"
          certificate_store           = "My"
      }
  }*/
  os_profile_windows_config {
    provision_vm_agent = true

    winrm {
      protocol = "HTTP"
    }

    /*
    winrm {
        protocol                    = "HTTPS"
        certificate_url             = ""
    }
    */
  }

  boot_diagnostics {
    enabled     = "${var.enableBootDiag}"
    storage_uri = "${var.Storage}"
  }

  tags {
    environment = "${var.environment}"
  }

  # depends_on                          = ["${element(azurerm_network_interface.Nic.*.id, count.index)}"]
}
