data "azurerm_subnet" "HospSubnet" {
    name                                = "${var.HospNumber}-Subnet"
    virtual_network_name                = "${var.HospNumber}-vNet"
    resource_group_name                 = "${var.ResourceGroupName}"
}

data "azurerm_client_config" "current" {

}

resource "random_string" "sqlAdminPassword" {
    length                              = 21
    special                             = true
    override_special                    = "!@*-" 
}

resource "azurerm_key_vault_secret" "HospSqlKeyVaultSecret" {
    name                                = "${var.HospNumber}-sqlAdminPassword"
    value                               = "${random_string.sqlAdminPassword.result}"
    key_vault_id                        = "${var.KeyVaultId}"

    tags {
        environment                     = "${var.environment}"
    }
}

resource "azurerm_sql_server" "azHospDbServer" {
    name                                = "${var.HospNumber}sqlerver"
    resource_group_name                 = "${var.ResourceGroupName}"
    location                            = "${var.location}"
    version                             = "12.0"
    administrator_login                 = "${var.HospNumber}SQLAdmin"
    administrator_login_password        = "${azurerm_key_vault_secret.HospSqlKeyVaultSecret.value}"

    tags {
        environment                     = "${var.environment}"
    }
}

resource "azurerm_sql_active_directory_administrator" "azHospDbServerAdAdmin" {
    server_name                         = "${azurerm_sql_server.azHospDbServer.name}"
    resource_group_name                 = "${var.ResourceGroupName}"
    login                               = "DBAdmins"
    tenant_id                           = "${data.azurerm_client_config.current.tenant_id}"
    object_id                           = "${data.azurerm_client_config.current.service_principal_object_id}"
}

/* Future Use
resource "azurerm_sql_firewall_rule" "azHospDbServerFirewallRule" {
    name                                = "${var.azHospNumber}FirewallRule1"
    resource_group_name                 = "${azurerm_resource_group.HospResourceGroup.name}"
    server_name                         = "${azurerm_sql_server.azHospDbServer.name}"
    start_ip_address                    = "10.0.17.62"
    end_ip_address                      = "10.0.17.62"
}*/

resource "azurerm_sql_virtual_network_rule" "azHospSqlNetwork" {
    name                                = "sql-vnet-rule-hosp${var.HospNumber}" # name cannot start with hyphen or number
    resource_group_name                 = "${var.ResourceGroupName}"
    server_name                         = "${azurerm_sql_server.azHospDbServer.name}"
    subnet_id                           = "${data.azurerm_subnet.HospSubnet.id}"
}

resource "azurerm_sql_database" "azHospDb" {
    name                                = "${var.HospNumber}DB"
    resource_group_name                 = "${var.ResourceGroupName}"
    location                            = "${var.location}"
    server_name                         = "${azurerm_sql_server.azHospDbServer.name}"
    create_mode                         = "Default"
    edition                             = "Standard"

    tags {
        environment                     = "${var.environment}"
    }
}



