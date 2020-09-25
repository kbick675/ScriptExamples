<#
AllNodes:
Settings for nodename * will apply to all systems. Typically limited to LCM settings.
Settings for nodenames that are unique will apply to only that system. Change, comment out or uncomment settings you want to use or change.
    CommonConfig references the CommontItems configuration settings and is used in DSC.  

CommonItems:
Settings that should apply to all VMs for the Server or application you're deploying for.
This is supposed to reduce the number of edits necessary. 
#>
@{
    AllNodes = @(
        @{
            NodeName                    = "*"
            PSDscAllowPlainTextPassword = $true
        }
        @{
            NodeName                    = '__SERVERHOSTNAME__' #Change this
            Role                        = 'WebServer'
            NodeNameFQDN                = "__SERVERHOSTNAME__.domain.com" #Change this
            Network                     = "VLAN 170"
            #IPAddress                  = "__IPADDRESS__" # Optional. Comment out the line if your target network has DHCP that you want to use
            #SubnetMask                  = "255.255.255.0"
            #GateWay                     = "__GATEWAYIP__" 
            CommonConfig                = 'CommonItems'
            Template                    = "server-tpl"
            VMvCPU                      = 2
            VMMemGB                     = 8
            PrimaryDiskSize             = 100
            AdditionalDiskCount         = 1
            AdditionalDiskSizes         = 200
        }
        @{
            NodeName                    = '__SERVERHOSTNAME__' #Change this
            Role                        = 'DBServer'
            NodeNameFQDN                = "__SERVERHOSTNAME__.domain.com" #Change this
            Network                     = "VLAN 170 - VCA DEV"
            #IPAddress                  = "__IPADDRESS__" # Optional. Comment out the line if your target network has DHCP that you want to use
            #SubnetMask                  = "255.255.255.0"
            #GateWay                     = "__GATEWAYIP__" 
            CommonConfig                = 'CommonItems'
            Template                    = "db-tpl"
            VMvCPU                      = 2
            VMMemGB                     = 16
            PrimaryDiskSize             = 100
            AdditionalDiskCount         = 3
            AdditionalDiskSizes         = 200, 100, 100
        }  
    );
    CommonItems = @(
        @{
            DNSServer1                  = "10.211.102.100"
            DNSServer2                  = "10.125.105.100"
            ConnectionSpecificSuffix    = "domain.com"
            TimeZone                    = "__TIMEZONE__"
            TargetOU                    = "OU=Computers,DC=domain,DC=com"
            ### VM Information for use with deployment script
            Requestor                   = "Kevin Bickmore"
            Department                  = "Server Engineering"
            Environment                 = "Production"
            Engineer                    = "Kevin Bickmore"
            VIServer                    = "vcenter.domain.com"
            OnVMC                       = $false
            Cluster                     = "Cluster"
            DataStore                   = "Storage Cluster"
            Datacenter                  = "Datacenter"
            OSCustomizationSpec         = "Windows_Domain_Join"
            FileServerPath              = "\\domain.com\folders\Apps\install_media"
            CertFilePath                = "\\domain.com\folders\Apps\certinstall\ww_domain_121317.pfx"
        }
    );
}

                       