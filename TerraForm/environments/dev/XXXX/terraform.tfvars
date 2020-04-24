## Environment Info ##
environment                 = "dev" # dev, prod
HospNumber                  = "0123"
location                    = "westus2" # westcentralus, centralus, westus, westus2, eastus, eastus2, northcentralus, southcentralus, canadacentral, canadaeast

## VMs ## 
VmSize                      = "Standard_DS3_v2" # NS Server = "Standard_DS3_v2" DB Server = "Standard_E4s_v3"
VmCount                     = 3 # Number of VMs
VmSku                       = "2019-Datacenter" # 2019-Datacenter, 2019-Datacenter-Core, 2016-Datacenter, 2016-Datacenter-Server-Core # This may be a custom image in the long run.

## Static Resource Information ##
ResourceGroup               = "General-Rg-Dev"
KeyVaultName                = "Secret-Vault-Dev"

## Networking ##
vNetSpace                   = "10.0.0.0/16"
subnet                      = "10.0.2.0/26"





