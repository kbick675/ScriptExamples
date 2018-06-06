param (
    [string]$NodeName
)
Configuration PostInstallationConfiguration
{
    param
    (
        [PSCredential]$ShellCreds,
        [PSCredential]$CertCreds
    )

    Import-DscResource -ModuleName xExchange -ModuleVersion 1.19.0.0
    Import-DscResource -ModuleName xWebAdministration -ModuleVersion 1.19.0.0
    Import-DscResource -ModuleName xCertificate -ModuleVersion 3.2.0.0
    
    #This section will handle configuring all non-DAG specific settings, including CAS and MBX settings.
    Node $AllNodes.NodeName
    {
        $dagSettings = $ConfigurationData[$Node.DAGId] #Look up and retrieve the DAG settings for this node
        $casSettings = $ConfigurationData[$Node.CASId] #Look up and retrieve the CAS settings for this node

        #Thumbprint of the certificate used to decrypt credentials on the target node
        <#
        LocalConfigurationManager
        {
            CertificateId = $Node.Thumbprint
        }
        #>
        WindowsFeature FailoverClustering
        {
            Ensure = 'Present'
            Name = "Failover-clustering"
        }
        ###General server settings###
        #This section licenses the server
        xExchExchangeServer EXServer
        {
            Identity            = $Node.NodeName
            Credential          = $ShellCreds
            ProductKey          = '7WJV6-H9RMH-F4267-3R2KG-F6PBY'
            AllowServiceRestart = $true
        }
        ###Transport specific settings###
        #Create a custom receive connector which could be used to receive SMTP mail from internal non-Exchange mail servers
        xExchReceiveConnector ShareX
        {
            Identity         = "$($Node.NodeName)\ShareX2013"
            Credential       = $ShellCreds
            Ensure           = 'Present'
            AuthMechanism    = 'None'
            Bindings         = '0.0.0.0:25'
            PermissionGroups = 'AnonymousUsers'
            RemoteIPRanges   = '10.34.3.80','10.34.1.53','10.34.1.55','10.34.1.45','10.34.1.48','10.34.1.47','10.34.1.52','10.34.1.54','10.34.1.43','10.34.1.44','10.34.1.42','10.1.45.222'
            TransportRole    = 'FrontendTransport'
            Usage            = 'Custom'
            MessageRateLimit = 'Unlimited'
            MessageRateSource = 'IPAddress'
            MaxInboundConnection = '5000'
            MaxInboundConnectionPerSource = '75'
            MaxInboundConnectionPercentagePerSource = 2
            MaxMessageSize   = '100MB'
            RequireTLS = $false
            RequireEHLODomain = $false
            SizeEnabled = 'Enabled'
            DeliveryStatusNotificationEnabled = $true
        }
        xExchReceiveConnector Default
        {
            Identity         = "$($Node.NodeName)\Default $($Node.NodeName)"
            Credential       = $ShellCreds
            AuthMechanism    = 'Tls','Integrated','BasicAuth','BasicAuthRequireTLS','ExchangeServer'
            PermissionGroups = 'ExchangeUsers','ExchangeServers','ExchangeLegacyServers'
            Ensure           = 'Present'
            MaxMessageSize   = '250MB'
        }
        xExchReceiveConnector DefaultFrontEnd
        {
            Identity         = "$($Node.NodeName)\Default Frontend $($Node.NodeName)"
            Credential       = $ShellCreds
            AuthMechanism    = 'Tls','Integrated','BasicAuth','BasicAuthRequireTLS','ExchangeServer'
            PermissionGroups = 'AnonymousUsers','ExchangeUsers','ExchangeServers','ExchangeLegacyServers'
            Ensure           = 'Present'
            MaxMessageSize   = '250MB'
            MaxRecipientsPerMessage = 500
        }
        xExchReceiveConnector OutboundProxyFrontend
        {
            Identity         = "$($Node.NodeName)\Outbound Proxy Frontend $($Node.NodeName)"
            Credential       = $ShellCreds
            AuthMechanism    = 'Tls','Integrated','BasicAuth','BasicAuthRequireTLS','ExchangeServer'   
            PermissionGroups = 'ExchangeServer'         
            Ensure           = 'Present'
            MaxMessageSize   = '250MB'
            MaxRecipientsPerMessage = 500
        }
        xExchReceiveConnector ClientFrontend
        {
            Identity         = "$($Node.NodeName)\Client Frontend $($Node.NodeName)"
            Credential       = $ShellCreds
            AuthMechanism    = 'Tls','Integrated','BasicAuth','BasicAuthRequireTLS','ExchangeServer'
            PermissionGroups = 'ExchangeUsers','ExchangeServers','ExchangeLegacyServers'
            Ensure           = 'Present'
            MaxMessageSize   = '250MB'
            MaxRecipientsPerMessage = 500
            MessageRateLimit = '25'
        }
        xExchReceiveConnector ClientProxy
        {
            Identity         = "$($Node.NodeName)\Client Proxy $($Node.NodeName)"
            Credential       = $ShellCreds
            AuthMechanism    = 'Tls','Integrated','BasicAuth','BasicAuthRequireTLS','ExchangeServer'
            PermissionGroups = 'ExchangeUsers','ExchangeServers'
            Ensure           = 'Present'
            MaxMessageSize   = '250MB'
            MaxRecipientsPerMessage = 500
            MessageRateLimit = '25'
        }
        xExchMailboxServer MailboxServer
        {
            Identity = "$($Node.NodeName)"
            Credential = $ShellCreds
            WacDiscoveryEndpoint = "$($casSettings.WacDiscoveryEndpoint)"
        }
        <#
        xExchTransportService TransportConfiguration
        {
            Identity = $Node.NodeName
            Credential = $ShellCreds
            AllowServiceRestart = $true
            MaxPerDomainOutboundConnections = '200'
        }
        #>
        #Ensures that Exchange built in AntiMalware Scanning is enabled or disabled
        xExchAntiMalwareScanning AMS
        {
            Enabled    = $true
            Credential = $ShellCreds
        }
        xExchClientAccessServer AutoDiscover
        {
            Identity                       = $Node.NodeName
            Credential                     = $ShellCreds
            AutoDiscoverServiceInternalUri = "https://$($casSettings.AutoDiscoverURL)/autodiscover/autodiscover.xml"
            AutoDiscoverSiteScope          = $casSettings.AutoDiscoverSiteScope
        }
        #Install features that are required for xExchActiveSyncVirtualDirectory to do Auto Certification Based Authentication
        WindowsFeature WebClientAuth
        {
            Name   = 'Web-Client-Auth'
            Ensure = 'Present'
        }
        WindowsFeature WebCertAuth
        {
            Name   = 'Web-Cert-Auth'
            Ensure = 'Present'
        }
        #This example shows how to enable Certificate Based Authentication for ActiveSync
        xExchActiveSyncVirtualDirectory ASVdir
        {
            Identity                    = "$($Node.NodeName)\Microsoft-Server-ActiveSync (Default Web Site)"
            Credential                  = $ShellCreds
            ExternalUrl                 = "https://$($casSettings.ExternalNLBFqdn)/Microsoft-Server-ActiveSync"  
            InternalUrl                 = "https://$($casSettings.InternalNLBFqdn)/Microsoft-Server-ActiveSync"  
            BasicAuthEnabled            = $true
            ClientCertAuth              = 'Ignore'
            CompressionEnabled          = $false
            WindowsAuthEnabled          = $false
            AllowServiceRestart         = $true
            DependsOn                   = '[WindowsFeature]WebClientAuth','[WindowsFeature]WebCertAuth'
            #NOTE: If CBA is being configured, this should also be dependent on the cert whose thumbprint is being used. See EndToEndExample.
        }
        #Ensures forms based auth and configures URLs
        xExchEcpVirtualDirectory ECPVDir
        {
            Identity                    = "$($Node.NodeName)\ecp (Default Web Site)"
            Credential                  = $ShellCreds
            ExternalUrl                 = "https://$($casSettings.ExternalNLBFqdn)/ecp"
            InternalUrl                 = "https://$($casSettings.InternalNLBFqdn)/ecp"           
            AdfsAuthentication          = $true
            FormsAuthentication         = $false
            BasicAuthentication         = $false
            WindowsAuthentication       = $false
            ExternalAuthenticationMethods = 'Adfs'
        }
        #Configure URL's and for NTLM and negotiate auth
        xExchMapiVirtualDirectory MAPIVdir
        {
            Identity                 = "$($Node.NodeName)\mapi (Default Web Site)"
            Credential               = $ShellCreds
            ExternalUrl              = "https://$($casSettings.InternalNLBFqdn)/mapi"
            IISAuthenticationMethods = 'Negotiate'
            InternalUrl              = "https://$($casSettings.InternalNLBFqdn)/mapi" 
            AllowServiceRestart      = $true
        }
        #Configure URL's and add any OABs this vdir should distribute
        xExchOabVirtualDirectory OABVdir
        {
            Identity            = "$($Node.NodeName)\OAB (Default Web Site)"
            Credential          = $ShellCreds
            ExternalUrl         = "https://$($casSettings.ExternalNLBFqdn)/oab"
            InternalUrl         = "https://$($casSettings.InternalNLBFqdn)/oab"     
            OABsToDistribute    = $casSettings.OABsToDistribute
            AllowServiceRestart = $true
        }
        #Configure URL's and auth settings
        xExchOutlookAnywhere OAVdir
        {
            Identity                           = "$($Node.NodeName)\Rpc (Default Web Site)"
            Credential                         = $ShellCreds
            ExternalClientAuthenticationMethod = 'Negotiate'
            ExternalClientsRequireSSL          = $true
            ExternalHostName                   = $casSettings.InternalNLBFqdn
            IISAuthenticationMethods           = 'Ntlm','Basic','Negotiate'
            InternalClientAuthenticationMethod = 'Negotiate'
            InternalClientsRequireSSL          = $true
            InternalHostName                   = $casSettings.InternalNLBFqdn
            AllowServiceRestart                = $true
            SSLOffloading                      = $true
        }
        #Ensures forms based auth and configures URLs and IM integration
        xExchOwaVirtualDirectory OWAVdir
        {
            Identity                                = "$($Node.NodeName)\owa (Default Web Site)"
            Credential                              = $ShellCreds
            ExternalUrl                             = "https://$($casSettings.ExternalNLBFqdn)/owa"
            InternalUrl                             = "https://$($casSettings.InternalNLBFqdn)/owa"    
            AdfsAuthentication                      = $true
            InstantMessagingEnabled                 = $true
            InstantMessagingCertificateThumbprint   = "$($casSettings.IMCertificateThumbprint)"
            InstantMessagingServerName              = "$($casSettings.InstantMessagingServerName)"
            InstantMessagingType                    = 'Ocs'
            AllowServiceRestart                     = $true
            DefaultDomain                           = 'spacex.corp'
            WindowsAuthentication                   = $false
            BasicAuthentication                     = $false
            FormsAuthentication                     = $false
        }
        #Turn on Windows Integrated auth for remote powershell connections
        xExchPowerShellVirtualDirectory PSVdir
        {
            Identity              = "$($Node.NodeName)\PowerShell (Default Web Site)"
            Credential            = $ShellCreds
            WindowsAuthentication = $true
            AllowServiceRestart   = $true
        }
        #Configure EWS URL's
        xExchWebServicesVirtualDirectory EWSVdir
        {
            Identity            = "$($Node.NodeName)\EWS (Default Web Site)"
            Credential          = $ShellCreds
            ExternalUrl         = "https://$($casSettings.ExternalNLBFqdn)/ews/exchange.asmx" 
            InternalUrl         = "https://$($casSettings.InternalNLBFqdn)/ews/exchange.asmx"
            AllowServiceRestart = $true 
            BasicAuthentication =  $true
            WSSecurityAuthentication = $true
            WindowsAuthentication = $true
            OAuthAuthentication = $true
            DigestAuthentication = $false     
        }
        xWebConfigKeyValue ActiveSyncMaxDocumentDataSizeBackend
        {
            Ensure          = 'Present'
            ConfigSection   = "AppSettings"
            Key             = 'MaxDocumentDataSize'
            Value           = '268435456'
            WebsitePath     = 'IIS:\Sites\Exchange Back End\Microsoft-Server-ActiveSync'
        }
        xWebConfigKeyValue ActiveSyncConcurrencyGuardsDefault
        {
            Ensure          = 'Present'
            ConfigSection   = "AppSettings"
            Key             = 'HttpProxy.ConcurrencyGuards.TargetBackendLimit'
            Value           = '5000'
            WebsitePath     = 'IIS:\Sites\Default Web Site\Microsoft-Server-ActiveSync'
        }
        xWebConfigKeyValue rpcConcurrencyGuardsDefault
        {
            Ensure          = 'Present'
            ConfigSection   = "AppSettings"
            Key             = 'HttpProxy.ConcurrencyGuards.TargetBackendLimit'
            Value           = '5000'
            WebsitePath     = 'IIS:\Sites\Default Web Site\rpc'
        }
        xWebConfigKeyValue ewsConcurrencyGuardsDefault
        {
            Ensure          = 'Present'
            ConfigSection   = "AppSettings"
            Key             = 'HttpProxy.ConcurrencyGuards.TargetBackendLimit'
            Value           = '5000'
            WebsitePath     = 'IIS:\Sites\Default Web Site\EWS'
        }
        xWebConfigKeyValue OwaIMCertBackend
        {
            Ensure          = 'Present'
            ConfigSection   = "AppSettings"
            Key             = 'IMCertificateThumbprint'
            Value           = "$($casSettings.IMCertificateThumbprint)"
            WebsitePath     = 'IIS:\Sites\Exchange Back End\owa'
        }
        xWebConfigKeyValue OwaIMServerBackend
        {
            Ensure          = 'Present'
            ConfigSection   = "AppSettings"
            Key             = 'IMServerName'
            Value           = "$($casSettings.InstantMessagingServerName)"
            WebsitePath     = 'IIS:\Sites\Exchange Back End\owa'
        }
        $ExchWebsites = @(
            'Default Web Site/OWA',
            'Default Web Site/ecp',
            'Default Web Site/EWS',
            'Default Web Site/Autodiscover',
            'Default Web Site/Microsoft-Server-ActiveSync',
            'Default Web Site/OAB',
            'Default Web Site/MAPI'
        )
        foreach ($Website in $ExchWebsites)
        {
            xSSLSettings "sslFlags-$($Website)"
            {
                Name = $Website
                Bindings = ''
            }
        }
        
        Registry MSExchOWAPrivateTimeout
        {
            Ensure = 'Present'
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Services\MSExchange OWA'
            ValueName = 'PrivateTimeout'
            ValueData = '60'
            ValueType = 'Dword'
        }
        Registry MSExchOWAPublicTimeout
        {
            Ensure = 'Present'
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Services\MSExchange OWA'
            ValueName = 'PublicTimeout'
            ValueData = '5'
            ValueType = 'Dword'
        }
        Registry TCPKeepalive
        {
            Ensure = 'Present'
            Key = 'HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters'
            ValueName = 'KeepAliveTime'
            ValueData = '1200000'
            ValueType = 'Dword'
        }
        Registry MinTCPKeepalive
        {
            Ensure = 'Present'
            Key = 'HKLM:\Software\Policies\Microsoft\Windows NT\RPC'
            ValueName = 'MinimumConnectionTimeout'
            ValueData = '120'
            ValueType = 'Dword'
        }
        Service Imap4BE
        {
            Name = "MSExchangeImap4BE"
            State = "Running"
            StartupType = "Automatic"
        }
        Service Imap4
        {
            Name = "MSExchangeImap4"
            State = "Running"
            StartupType = "Automatic"
        }
        xCertificateImport adfssigning
        {
            Thumbprint = $casSettings.ADFSSigningThumbprint
            Location   = 'LocalMachine'
            Store      = 'Root'
            Path       = $casSettings.ADFSSigningPath
        }
        Script XForwardedFor
        {
            SetScript = {
                Import-Module WebAdministration
                $Websites = Get-Website
                foreach ($Website in $Websites)
                {
                    Add-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/site[@ID=$($Website.ID)]/logFile/customFields" -Name "." -Value @{logFieldName='X-Forwarded-For';sourceName='X-FORWARDED-FOR';sourceType='RequestHeader'}
                    Write-Verbose -Message "[Script]Set: X-FORWARDED-FOR logging configuration added."
                }
            }
            TestScript = {
                Import-Module WebAdministration
                $WebSites = Get-WebSite
                foreach ($WebSite in $WebSites)
                {
                    $xforwardedfor = Get-WebConfiguration -PSPath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/site[@ID=$($Website.ID)]/logFile/customFields/*"| where logFieldName -eq "X-Forwarded-For" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    if (!($xforwardedfor))
                    {
                        Write-Verbose -Message "$($Website.Name) does not have X-Forwarded-For set."
                        return $false
                    }
                    elseif ($xforwardedfor)
                    {
                        Write-Verbose -Message "[Script]Test: X-FORWARDED-FOR logging configuration exists."
                        Write-Verbose -Message "[Script]Test: $($Website.name)"
                        Write-Verbose -Message "[Script]Test: logFieldName: $($xforwardedfor.logFieldName)"
                        Write-Verbose -Message "[Script]Test: sourceName: $($xforwardedfor.sourceName)"
                        Write-Verbose -Message "[Script]Test: sourceType: $($xforwardedfor.sourceType)"
                        return $true
                    }
                }
            }
            GetScript = {
                return @{
                    TestScript = $TestScript
                }
            }
        }
        Script ImapConfigXml
        {
            SetScript = {
                [xml]$xmlImapConfig = Get-Content -Path 'C:\Program Files\Microsoft\Exchange Server\V15\ClientAccess\PopImap\Microsoft.Exchange.Imap4.exe.config'
                if ($xmlImapConfig.configuration.appSettings.add | Where-Object {$_.Key -eq 'AllowCrossSiteSessions'})
                {
                    $xmlImapConfig.configuration.appSettings.add | Where-Object {$_.Key -eq 'AllowCrossSiteSessions'} | ForEach-Object {$_.value = 'true'}
                    $xmlImapConfig.Save("$env:ProgramFiles\Microsoft\Exchange Server\V15\ClientAccess\PopImap\Microsoft.Exchange.Imap4.exe.config")
                }
                elseif (!($xmlImapConfig.configuration.appSettings.add | Where-Object {$_.Key -eq 'AllowCrossSiteSessions'}))
                {
                    $newEl=$xmlImapConfig.CreateElement("add");                         # Create a new Element 
                    $nameAtt1=$xmlImapConfig.CreateAttribute("key");                    # Create a new attribute 
                    $nameAtt1.psbase.value="AllowCrossSiteSessions";                    # Set the value of attribute 
                    $newEl.SetAttributeNode($nameAtt1);                                 # Attach the attribute 
                    $nameAtt2=$xmlImapConfig.CreateAttribute("value");                  # Create attribute  
                    $nameAtt2.psbase.value="true";                                      # Set the value of attribute 
                    $newEl.SetAttributeNode($nameAtt2);                                 # Attach the attribute 
                    $xmlImapConfig.configuration["appSettings"].AppendChild($newEl);    # Add the newly created element to the right position
                    $xmlImapConfig.Save("$env:ProgramFiles\Microsoft\Exchange Server\V15\ClientAccess\PopImap\Microsoft.Exchange.Imap4.exe.config")
                }
                Restart-Service -Name MSExchangeIMAP4BE
                Restart-Service -Name MSExchangeImap4
            }
            TestScript = {
                [xml]$xmlImapConfig = Get-Content -Path 'C:\Program Files\Microsoft\Exchange Server\V15\ClientAccess\PopImap\Microsoft.Exchange.Imap4.exe.config'
                if ($xmlImapConfig.configuration.appSettings.add | Where-Object {$_.Key -eq 'AllowCrossSiteSessions'})
                {
                    return $true
                }
                elseif (!($xmlImapConfig.configuration.appSettings.add | Where-Object {$_.Key -eq 'AllowCrossSiteSessions'}))
                {
                    return $false
                }
            }
            GetScript = {
                return @{
                    TestScript = $TestScript
                }
            }
        }
        Script QueueDBConfigXml
        {
            SetScript = {
                Write-Verbose -Message '[Script]Set: Changing Transport Configuration Values'
                [xml]$xmlTranportConfig = Get-Content -Path "$env:ProgramFiles\Microsoft\Exchange Server\V15\Bin\EdgeTransport.exe.config"
                $xmlTranportConfig.configuration.appSettings.add | Where-Object {$_.Key -eq 'DatabaseCheckPointDepthMax'} | ForEach-Object {$_.value = '512MB'}
                Write-Verbose -Message '[Script]Set: Changing Transport Configuration Value DatabaseCheckPointDepthMax to 512MB'
                $xmlTranportConfig.configuration.appSettings.add | Where-Object {$_.Key -eq 'DatabaseMaxCacheSize'} | ForEach-Object {$_.value = '1024MB'}
                Write-Verbose -Message '[Script]Set: Changing Transport Configuration Value DatabaseMaxCacheSize to 1024MB'
                $xmlTranportConfig.configuration.appSettings.add | Where-Object {$_.Key -eq 'DatabaseMinCacheSize'} | ForEach-Object {$_.value = '64MB'}
                Write-Verbose -Message '[Script]Set: Changing Transport Configuration Value DatabaseMinCacheSize to 64MB'
                $xmlTranportConfig.configuration.appSettings.add | Where-Object {$_.Key -eq 'QueueDatabasePath'} | ForEach-Object {$_.value = "$($env:SystemDrive)\dragonbreath\QueueDB\Queue"}
                Write-Verbose -Message "[Script]Set: Changing Transport Configuration Value QueueDatabasePath to $($env:SystemDrive)\dragonbreath\QueueDB\Queue"
                $xmlTranportConfig.configuration.appSettings.add | Where-Object {$_.Key -eq 'QueueDatabaseLoggingPath'} | ForEach-Object {$_.value = "$($env:SystemDrive)\dragonbreath\QueueDB\QueueLogs"}
                Write-Verbose -Message "[Script]Set: Changing Transport Configuration Value DatabaseCheckPointDepthMax to $($env:SystemDrive)\dragonbreath\QueueDB\QueueLogs"
                $xmlTranportConfig.Save("$env:ProgramFiles\Microsoft\Exchange Server\V15\Bin\EdgeTransport.exe.config")
                Restart-Service -Name MSExchangeTransport
            }
            TestScript = {
                if (!(Test-Path -Path "$($env:SystemDrive)\dragonbreath\QueueDB"))
                {
                    return $false
                }
                if (!(Test-Path -Path "$($env:SystemDrive)\dragonbreath\QueueDB\Queue\mail.que"))
                {
                    return $false
                }
                if (Test-Path -Path "$($env:SystemDrive)\dragonbreath\QueueDB\Queue\mail.que")
                {
                    return $true
                }
            }
            GetScript = {
                return @{
                    TestScript = $TestScript
                }
            }
        }
        Script ActiveSyncDefaultDomain
        {
            SetScript = {
                Write-Verbose -Message '[Script]Set: Changing ActiveSync Basic Auth Configuration Value for Default Domain to spacex.corp'
                Set-WebConfigurationProperty -PSPath 'IIS:\' -Filter '/system.webServer/security/authentication/basicAuthentication' -Name defaultLogonDomain -Value 'spacex.corp' -Location 'Default Web Site/Microsoft-Server-ActiveSync'
            }
            TestScript = {
                $ASBasic = Get-WebConfigurationProperty -PSPath 'IIS:\Sites\Default Web Site\Microsoft-Server-ActiveSync\' -Filter '/system.webServer/security/authentication/basicAuthentication' -Name defaultLogonDomain
                if ($ASBasic.Value -ne 'spacex.corp')
                {
                    return $false
                }
                elseif ($ASBasic.Value -eq 'spacex.corp')
                {
                    return $true
                }
            }
            GetScript = {
                return @{
                    TestScript = $TestScript
                }
            }
        }
        Script ActiveSyncMaxRequestLength
        {
            SetScript = {
                Write-Verbose -Message '[Script]Set: Changing ActiveSync maxRequestLenth value to 204800'
                Set-WebConfigurationProperty -PSPath 'IIS:\Sites\Default Web Site\Microsoft-Server-ActiveSync' -Filter '/system.web/httpRuntime' -Name maxRequestLength -Value '204800'
                Set-WebConfigurationProperty -PSPath 'IIS:\Sites\Exchange Back End\Microsoft-Server-ActiveSync' -Filter '/system.web/httpRuntime' -Name maxRequestLength -Value '204800'
            }
            TestScript = {
                $ASMRL1 = Get-WebConfigurationProperty -PSPath 'IIS:\Sites\Default Web Site\Microsoft-Server-ActiveSync' -Filter '/system.web/httpRuntime' -Name maxRequestLength
                $ASMRL2 = Get-WebConfigurationProperty -PSPath 'IIS:\Sites\Exchange Back End\Microsoft-Server-ActiveSync' -Filter '/system.web/httpRuntime' -Name maxRequestLength
                if (($ASMRL1.Value -ne '204800') -or ($ASMRL2.Value -ne '204800'))
                {
                    return $false
                }
                if (($ASMRL1.Value -eq '204800') -and ($ASMRL2.Value -eq '204800'))
                {
                    return $true
                }
            }
            GetScript = {
                return @{
                    TestScript = $TestScript
                }
            }
        }
        Script owaMaxRequestLength
        {
            SetScript = {
                Write-Verbose -Message '[Script]Set: Changing OWA maxRequestLenth value to 204800'
                Set-WebConfigurationProperty -PSPath 'IIS:\Sites\Default Web Site\owa' -Filter '/system.web/httpRuntime' -Name maxRequestLength -Value '204800' 
                Set-WebConfigurationProperty -PSPath 'IIS:\Sites\Exchange Back End\owa' -Filter '/system.web/httpRuntime' -Name maxRequestLength -Value '204800'
                Set-WebConfigurationProperty -PSPath 'IIS:\Sites\Exchange Back End\owa' -Filter '/system.serviceModel/bindings/webHttpBinding/binding' -Name maxReceivedMessageSize -Value '268435456'
                Set-WebConfigurationProperty -PSPath 'IIS:\Sites\Exchange Back End\owa' -Filter '/system.serviceModel/bindings/webHttpBinding/binding/readerQuotas' -Name maxStringContentLength -Value '268435456'
            }
            TestScript = {
                $OWAMRL1 = Get-WebConfigurationProperty -PSPath 'IIS:\Sites\Default Web Site\owa' -Filter '/system.web/httpRuntime' -Name maxRequestLength
                $OWAMRL2 = Get-WebConfigurationProperty -PSPath 'IIS:\Sites\Exchange Back End\owa' -Filter '/system.web/httpRuntime' -Name maxRequestLength
                $OWAMRMS = Get-WebConfigurationProperty -PSPath 'IIS:\Sites\Exchange Back End\owa' -Filter '/system.serviceModel/bindings/webHttpBinding/binding' -Name maxReceivedMessageSize
                $OWAMSCL = Get-WebConfigurationProperty -PSPath 'IIS:\Sites\Exchange Back End\owa' -Filter '/system.serviceModel/bindings/webHttpBinding/binding/readerQuotas' -Name maxStringContentLength

                if (($OWAMRL1.Value -ne '204800') -or ($OWAMRL2.Value -ne '204800') -or ($OWAMRMS.Value -ne '268435456') -or ($OWAMSCL.Value -ne '268435456'))
                {
                    return $false
                }
                if (($OWAMRL1.Value -eq '204800') -and ($OWAMRL2.Value -eq '204800') -and ($OWAMRMS.Value -eq '268435456') -and ($OWAMSCL.Value -eq '268435456'))
                {
                    return $true
                }
            }
            GetScript = {
                return @{
                    TestScript = $TestScript
                }
            }
        }
        Script owaMaxAllowedContentLength
        {
            SetScript = {
                Write-Verbose -Message '[Script]Set: Changing OWA maxAllowedContentLength value to 268435456'
                [xml]$xmlDefOWA = Get-Content -Path "$env:ProgramFiles\Microsoft\Exchange Server\V15\FrontEnd\HttpProxy\owa\web.config"
                $xmlDefOWA.configuration.location.'system.webServer'.security.requestFiltering.requestLimits.maxAllowedContentLength = '268435456'
                $xmlDefOWA.Save("$env:ProgramFiles\Microsoft\Exchange Server\V15\FrontEnd\HttpProxy\owa\web.config")
                [xml]$xmlEbeOWA = Get-Content -Path "$env:ProgramFiles\Microsoft\Exchange Server\V15\ClientAccess\Owa\web.config"
                $xmlEbeOWA.configuration.location.'system.webServer'.security.requestFiltering.requestLimits.maxAllowedContentLength = '268435456'
                $xmlEbeOWA.Save("$env:ProgramFiles\Microsoft\Exchange Server\V15\ClientAccess\Owa\web.config")
            }
            TestScript = {
                [xml]$xmlDefOWA = Get-Content -Path "$env:ProgramFiles\Microsoft\Exchange Server\V15\FrontEnd\HttpProxy\owa\web.config"
                [xml]$xmlEbeOWA = Get-Content -Path "$env:ProgramFiles\Microsoft\Exchange Server\V15\ClientAccess\Owa\web.config"
                $OWADefMACL = $xmlDefOWA.configuration.location.'system.webServer'.security.requestFiltering.requestLimits.maxAllowedContentLength
                $OWAEbeMACL = $xmlEbeOWA.configuration.location.'system.webServer'.security.requestFiltering.requestLimits.maxAllowedContentLength

                if (($OWADefMACL -ne '268435456') -or ($OWAEbeMACL -ne '268435456'))
                {
                    return $false
                }
                if (($OWADefMACL -eq '268435456') -and ($OWAEbeMACL -eq '268435456'))
                {
                    return $true
                }
            }
            GetScript = {
                return @{
                    TestScript = $TestScript
                }
            }
        }
        Script EWSDefaultDomain
        {
            SetScript = {
                Write-Verbose -Message '[Script]Set: Changing EWS Basic Auth Configuration Value for Default Domain to spacex.corp'
                Set-WebConfigurationProperty -PSPath 'IIS:\' -Filter '/system.webServer/security/authentication/basicAuthentication' -Name defaultLogonDomain -Value 'spacex.corp' -Location 'Default Web Site/EWS'
            }
            TestScript = {
                $ASBasic = Get-WebConfigurationProperty -PSPath 'IIS:\Sites\Default Web Site\EWS\' -Filter '/system.webServer/security/authentication/basicAuthentication' -Name defaultLogonDomain
                if ($ASBasic.Value -ne 'spacex.corp')
                {
                    return $false
                }
                if ($ASBasic.Value -eq 'spacex.corp')
                {
                    return $true
                }
            }
            GetScript = {
                return @{
                    TestScript = $TestScript
                }
            }
        }
        Script EWSMaxAllowedContentLength
        {
            SetScript = {
                Write-Verbose -Message '[Script]Set: Changing EWS maxAllowedContentLength value to 314572800'
                [xml]$xmlDefEWSMailbox = Get-Content -Path "$env:ProgramFiles\Microsoft\Exchange Server\V15\ClientAccess\exchweb\ews\web.config"
                $xmlDefEWSMailbox.configuration.'system.webServer'.security.requestFiltering.requestLimits.maxAllowedContentLength = '314572800'
                $EWSBinding1 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.customBinding.binding | Where-Object {$_.name -eq 'EWSAnonymousHttpsBinding'}
                $EWSBinding1.httpsTransport.maxReceivedMessageSize = '314572800' ## set value
                $EWSBinding2 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.customBinding.binding | Where-Object {$_.name -eq 'EWSAnonymousHttpBinding'}
                $EWSBinding2.httpTransport.maxReceivedMessageSize = '314572800' ## set value
                $EWSBinding3 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.customBinding.binding | Where-Object {$_.name -eq 'EWSBasicHttpsBinding'}
                $EWSBinding3.httpsTransport.maxReceivedMessageSize = '314572800' ## set value
                $EWSBinding4 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.customBinding.binding | Where-Object {$_.name -eq 'EWSBasicHttpBinding'}
                $EWSBinding4.httpTransport.maxReceivedMessageSize = '314572800' ## set value
                $EWSBinding5 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.customBinding.binding | Where-Object {$_.name -eq 'EWSNegotiateHttpsBinding'}
                $EWSBinding5.httpsTransport.maxReceivedMessageSize = '314572800' ## set value
                $EWSBinding6 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.customBinding.binding | Where-Object {$_.name -eq 'EWSNegotiateHttpBinding'}
                $EWSBinding6.httpTransport.maxReceivedMessageSize = '314572800' ## set value
                $EWSBinding7 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.customBinding.binding | Where-Object {$_.name -eq 'EWSWSSecurityHttpsBinding'}
                $EWSBinding7.httpsTransport.maxReceivedMessageSize = '314572800' ## set value
                $EWSBinding8 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.customBinding.binding | Where-Object {$_.name -eq 'EWSWSSecurityHttpBinding'}
                $EWSBinding8.httpTransport.maxReceivedMessageSize = '314572800' ## set value
                $EWSBinding9 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.customBinding.binding | Where-Object {$_.name -eq 'EWSWSSecuritySymmetricKeyHttpsBinding'}
                $EWSBinding9.httpsTransport.maxReceivedMessageSize = '314572800' ## set value
                $EWSBinding10 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.customBinding.binding | Where-Object {$_.name -eq 'EWSWSSecuritySymmetricKeyHttpBinding'}
                $EWSBinding10.httpTransport.maxReceivedMessageSize = '314572800' ## set value
                $EWSBinding11 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.customBinding.binding | Where-Object {$_.name -eq 'EWSWSSecurityX509CertHttpsBinding'}
                $EWSBinding11.httpsTransport.maxReceivedMessageSize = '314572800' ## set value
                $EWSBinding12 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.customBinding.binding | Where-Object {$_.name -eq 'EWSWSSecurityX509CertHttpBinding'}
                $EWSBinding12.httpTransport.maxReceivedMessageSize = '314572800' ## set value
                $EWSBinding13 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.webHttpBinding.binding | Where-Object {$_.name -eq 'EWSStreamingNegotiateHttpsBinding'}
                $EWSBinding13.maxReceivedMessageSize = '314572800' ## set value
                $EWSBinding14 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.webHttpBinding.binding | Where-Object {$_.name -eq 'EWSStreamingNegotiateHttpBinding'}
                $EWSBinding14.maxReceivedMessageSize = '314572800' ## set value
                $xmlDefEWSMailbox.Save("$env:ProgramFiles\Microsoft\Exchange Server\V15\ClientAccess\exchweb\ews\web.config")
                [xml]$xmlDefEWSProxy = Get-Content -Path "$env:ProgramFiles\Microsoft\Exchange Server\V15\FrontEnd\HttpProxy\ews\web.config"
                $xmlDefEWSProxy.configuration.'system.webServer'.security.requestFiltering.requestLimits.maxAllowedContentLength = '314572800' ## set value
                $xmlDefEWSProxy.Save("$env:ProgramFiles\Microsoft\Exchange Server\V15\FrontEnd\HttpProxy\ews\web.config")
            }
            TestScript = {
                [xml]$xmlDefEWSProxy = Get-Content -Path "$env:ProgramFiles\Microsoft\Exchange Server\V15\FrontEnd\HttpProxy\ews\web.config"
                [xml]$xmlDefEWSMailbox = Get-Content -Path "$env:ProgramFiles\Microsoft\Exchange Server\V15\ClientAccess\exchweb\ews\web.config"
                $EWSEbeMACL = $xmlDefEWSMailbox.configuration.'system.webServer'.security.requestFiltering.requestLimits.maxAllowedContentLength 
                $EWSDefProxyMACL = $xmlDefEWSProxy.configuration.'system.webServer'.security.requestFiltering.requestLimits.maxAllowedContentLength
                $EWSBinding1 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.customBinding.binding | Where-Object {$_.name -eq 'EWSAnonymousHttpsBinding'}
                $EWSBinding2 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.customBinding.binding | Where-Object {$_.name -eq 'EWSAnonymousHttpBinding'}
                $EWSBinding14 = $xmlDefEWSMailbox.configuration.'system.serviceModel'.bindings.webHttpBinding.binding | Where-Object {$_.name -eq 'EWSStreamingNegotiateHttpBinding'}

                if (($EWSBinding14.maxReceivedMessageSize -ne '314572800') -or ($EWSBinding1.httpsTransport.maxReceivedMessageSize -ne '314572800') -or ($EWSBinding2.httpsTransport.maxReceivedMessageSize -ne '314572800') -or ($EWSEbeMACL -ne '314572800') -or ($EWSDefProxyMACL -ne '314572800'))
                {
                    return $false
                }
                if (($EWSBinding14.maxReceivedMessageSize -eq '314572800') -and ($EWSBinding1.httpsTransport.maxReceivedMessageSize -eq '314572800') -and ($EWSBinding2.httpsTransport.maxReceivedMessageSize -eq '314572800') -and ($EWSEbeMACL -eq '314572800') -and ($EWSDefProxyMACL -eq '314572800'))
                {
                    return $true
                }
            }
            GetScript = {
                return @{
                    TestScript = $TestScript
                }
            }
        }
    }
}

if ($null -eq $ShellCreds)
{
    $ShellCreds = Get-Credential -Message 'Enter credentials for establishing Remote Powershell sessions to Exchange'
}
<#
if ($null -eq $CertCreds)
{
    $CertCreds = Get-Credential -UserName 'PfxPassword' -Message 'Enter credentials for importing the Exchange certificate'
}
#>

$StartingLocation = Get-Location

Push-Location \\filer1\ist\ps\dsc\Config

###Compiles the example
PostInstallationConfiguration -ConfigurationData '\\path\to\dsc\Exchange2016Setup\Configs\ExchangeConfiguration.psd1' -ShellCreds $ShellCreds #-CertCreds $CertCreds

###Sets up LCM on target computers to decrypt credentials.
#Set-DscLocalConfigurationManager -Path .\PostInstallationConfiguration -Verbose

###Pushes configuration and waits for execution
#Start-DscConfiguration -Path .\PostInstallationConfiguration -Verbose -Wait 

Push-Location $StartingLocation