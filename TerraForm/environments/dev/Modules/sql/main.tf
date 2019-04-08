resource "azurerm_sql_server" "azDbServer" {
  name                         = "${var.Number}sqlerver"
  resource_group_name          = "${var.ResourceGroupName}"
  location                     = "${var.location}"
  version                      = "12.0"
  administrator_login          = "${var.Number}SQLAdmin"
  administrator_login_password = "${var.sqlAdminPw}"

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_sql_active_directory_administrator" "azDbServerAdAdmin" {
  server_name         = "${azurerm_sql_server.azDbServer.name}"
  resource_group_name = "${var.ResourceGroupName}"
  login               = "DBAdmins"
  tenant_id           = "${var.tenant_id}"
  object_id           = "${var.object_id}"
}

/* Future Use
resource "azurerm_sql_firewall_rule" "azDbServerFirewallRule" {
    name                                = "${var.azNumber}FirewallRule1"
    resource_group_name                 = "${azurerm_resource_group.ResourceGroup.name}"
    server_name                         = "${azurerm_sql_server.azDbServer.name}"
    start_ip_address                    = "10.0.17.62"
    end_ip_address                      = "10.0.17.62"
}*/

resource "azurerm_sql_virtual_network_rule" "azSqlNetwork" {
  name                = "sql-vnet-rule-${var.Number}"           # name cannot start with hyphen or number
  resource_group_name = "${var.ResourceGroupName}"
  server_name         = "${azurerm_sql_server.azDbServer.name}"
  subnet_id           = "${var.subnet_id}"
}

resource "azurerm_sql_database" "azDb" {
  name                = "${var.Number}DB"
  resource_group_name = "${var.ResourceGroupName}"
  location            = "${var.location}"
  server_name         = "${azurerm_sql_server.azDbServer.name}"
  create_mode         = "Default"
  edition             = "Standard"

  tags {
    environment = "${var.environment}"
  }
}
