resource "random_string" "vmLocalPassword" {
    length                              = 21
    special                             = true
    override_special                    = "!@*-" 
}
resource "azurerm_key_vault_secret" "HospVmKeyVaultSecret" {
    name                                = "h${var.HospNumber}-${var.vmSuffix}${1 + count.index}localPassword"
    value                               = "${random_string.vmLocalPassword.result}"
    key_vault_id                        = "${var.KeyVaultId}"
    count                               = "${var.count}"

    tags {
        environment                     = "${var.environment}"
    }
}

resource "azurerm_virtual_machine" "HospVM" {
    name                                = "h${var.HospNumber}-${var.vmSuffix}${1 + count.index}"
    location                            = "${var.location}"
    resource_group_name                 = "${var.ResourceGroup}"
    network_interface_ids               = ["${element(azurerm_network_interface.HospNic.*.id, count.index)}"]
    vm_size                             = "${var.VmSize}"
    delete_data_disks_on_termination    = true
    delete_os_disk_on_termination       = true
    count                               = "${var.count}"

    storage_os_disk {
        name                            = "h${var.HospNumber}-${var.vmSuffix}${1 + count.index}-OsDisk"
        caching                         = "ReadWr"
        create_option                   = "FromImage"
        managed_disk_type               = "Premium_LRS"
    }

    storage_image_reference {
        publisher                       = "MicrosoftWindowsServer"
        offer                           = "WindowsServer"
        sku                             = "${var.VmSku}"
        version                         = "latest"
    }

    os_profile {
        computer_name                   = "h${var.HospNumber}-${var.vmSuffix}${1 + count.index}"
        admin_username                  = "azureadmin"
        admin_password                  = "${element(azurerm_key_vault_secret.HospVmKeyVaultSecret.*.value, count.index)}"
    }

    boot_diagnostics {
        enabled                         = "${var.enableBootDiag}"
        storage_uri                     = "${var.HospStorage}"
    }

    tags {
        environment                     = "${var.environment}"
    }

    # depends_on                          = ["${element(azurerm_network_interface.HospNic.*.id, count.index)}"]
}