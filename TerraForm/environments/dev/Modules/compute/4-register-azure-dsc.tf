resource "azurerm_virtual_machine_extension" "dsc" {
  name                 = "DevOpsDSC"
  location             = var.location
  resource_group_name  = var.ResourceGroupName
  virtual_machine_name = element(azurerm_virtual_machine.HospVM.*.name, count.index)
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.9.1.0"
  depends_on           = [azurerm_virtual_machine.HospVM]

  settings = <<SETTINGS
      {
          "WmfVersion": "latest",
          "ModulesUrl": "https://eus2oaasibizamarketprod1.blob.core.windows.net/automationdscpreview/RegistrationMetaConfigV2.zip",
          "ConfigurationFunction": "RegistrationMetaConfigV2.ps1\\RegistrationMetaConfigV2",
          "Privacy": {
              "DataCollection": ""
          },
          "Properties": {
              "RegistrationKey": {
                "UserName": "PLACEHOLDER_DONOTUSE",
                "Password": "PrivateSettingsRef:registrationKeyPrivate"
              },
              "RegistrationUrl": "${var.dsc_endpoint}",
              "NodeConfigurationName": "",
              "ConfigurationMode": "applyAndMonitor",
              "ConfigurationModeFrequencyMins": 15,
              "RefreshFrequencyMins": 30,
              "RebootNodeIfNeeded": false,
              "ActionAfterReboot": "continueConfiguration",
              "AllowModuleOverwrite": false
          }
      }
    
SETTINGS


  protected_settings = <<PROTECTED_SETTINGS
      {
        "Items": {
          "registrationKeyPrivate" : "${var.dsc_key}"
        }
      }
    
PROTECTED_SETTINGS

}

