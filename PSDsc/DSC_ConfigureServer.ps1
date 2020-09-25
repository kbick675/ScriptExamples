param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if ($_ | Test-Path)
        {
            return $true
        }
        elseif (!($_ | Test-Path))
        {
            throw "Configuration file does not exist or path is incorrect."
        }
    })]
    [System.IO.FileInfo]
    $PathToConfigurationFile
)
##

Configuration Server_SingleNode {
    ## This will only work with Azure Automation
    $ADCreds = Get-AutomationPSCredential -Name 'AzAutomationRead'
    #$ADCreds = Get-Credential
    $PFXCreds = Get-AutomationPSCredential -Name 'wwpfxpw'
    #$PFXCreds = Get-Credential -UserName 'Ignore' -Message 'Password for PFX'
    ##
    Import-DscResource -ModuleName 'NetworkingDsc' -ModuleVersion 7.4.0.0
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xRemoteDesktopSessionHost' -ModuleVersion 1.9.0.0
    Import-DscResource -ModuleName 'StorageDsc' -ModuleVersion 4.9.0.0
    Import-DscResource -ModuleName 'ComputerManagementDsc' -ModuleVersion 8.1.0
    Import-DscResource -ModuleName 'xWebAdministration' -ModuleVersion 3.1.1
    Import-DscResource -ModuleName 'cNtfsAccessControl' -ModuleVersion 1.4.1
    Import-DscResource -ModuleName 'CertificateDsc' -ModuleVersion 4.7.0.0
    Import-DscResource -ModuleName 'cChoco' -ModuleVersion 2.4.0.0

    Node $AllNodes.Where{$_.Role -eq 'ConnectionBroker'}.NodeName { 
        $commonSettings = $ConfigurationData[$Node.CommonConfig]
        $NodeNameFQDN = $Node.NodeNameFQDN
        $RDLicenseServer = $commonSettings.RDLicenseServer
        $CollectionName = $commonSettings.CollectionName
        #region Computer Settings
        TimeZone setTimeZone {
            IsSingleInstance = "Yes"
            TimeZone = $commonSettings.TimeZone
        }
        #endregion Computer Settings
        #region Networking
        NetAdapterBinding DisableIPv6
        {
            InterfaceAlias = 'Ethernet0 2'
            ComponentId    = 'ms_tcpip6'
            State          = 'Disabled'
        }
        #endregion Networking
        #region RDS
        WindowsFeature Remote-Desktop-Services { 
            Ensure = "Present" 
            Name = "Remote-Desktop-Services"
        }
        WindowsFeature RDS-RD-Server  { 
            Ensure = "Present" 
            Name = "RDS-RD-Server" 
            DependsOn = "[WindowsFeature]Remote-Desktop-Services"
        }
        WindowsFeature RDS-Connection-Broker {
            Ensure = "Present"
            Name = "RDS-Connection-Broker"
            DependsOn = "[WindowsFeature]RDS-RD-Server"
        }
        WindowsFeature RSAT-RDS-Tools { 
            Ensure = "Present" 
            Name = "RSAT-RDS-Tools" 
            IncludeAllSubFeature = $true
        }
        Registry EnableRDP {
            Ensure = "Present"
            Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
            ValueName = "fDenyTSConnections"
            ValueData = "0"
            ValueType = "Dword"
        }
        Registry EnableRDPNLA {
            Ensure = "Present"
            Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
            ValueName = "UserAuthentication"
            ValueData = "1"
            ValueType = "Dword"
        }
        Registry SetRDLicenseServer {
            Ensure = "Present"
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsNT\Terminal Services"
            ValueName = "LicenseServers"
            ValueData = $commonSettings.RDLicenseServer
            ValueType = "String"
        }
        Script "RDSDeployment" {
            GetScript = {
                Write-Verbose "Getting list of RD Server roles."
                Import-Module RemoteDesktop
                if ((Get-Service -Name RDMS -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status) -ne 'Running') {
                    try
                    {
                        Start-Service -Name RDMS -ErrorAction Stop
                    }
                    catch 
                    {
                        Write-Warning "Failed to start RDMS service. Error: $_"
                    }
                }
                $Deployed = Get-RDServer -ErrorAction SilentlyContinue

                return @{
                    Result = ($Deployed | Where-Object Roles -contains "RDS-CONNECTION-BROKER").Server
                }
            }
            TestScript = {
                $state = Invoke-Expression -Command $GetScript
                if ($null -eq $state['Result']) {
                    return $false
                }
                elseif ($state['Result'] -eq $using:NodeNameFQDN) {
                    return $true
                }
            }
            SetScript = {
                Write-Verbose "Initiating new RDSH deployment."
                Import-Module RemoteDesktop
                New-RDSessionDeployment -ConnectionBroker $using:NodeNameFQDN -SessionHost $using:NodeNameFQDN
            }
            DependsOn = "[WindowsFeature]RDS-Connection-Broker"
        }
        Script "RDSLicensingConfig" {
            GetScript = {
                Write-Verbose "Getting RD License Server configuration."
                Import-Module RemoteDesktop
                $RDLicenseConfig = Get-RDLicenseConfiguration -ConnectionBroker $using:NodeNameFQDN
                return @{
                    Result = $RDLicenseConfig | Select-Object -ExpandProperty LicenseServer
                }
            }
            TestScript = {
                $state = Invoke-Expression -Command $GetScript
                if (($null -eq $state['Result']) -or ($state['Result'] -ne $using:RDLicenseServer)) {
                    return $false
                }
                elseif ($state['Result'] -eq $using:RDLicenseServer) {
                    return $true
                }
            }
            SetScript = {
                Write-Verbose "Configuring Licensing."
                Import-Module RemoteDesktop
                Set-RDLicenseConfiguration -Mode PerDevice -LicenseServer $using:RDLicenseServer -ConnectionBroker $using:NodeNameFQDN -Force
            }
            DependsOn = @("[WindowsFeature]RDS-Connection-Broker","[Script]RDSDeployment")
        }
        Script "RDSCollection" {
            GetScript = {
                Write-Verbose "Getting RD Session Host configuration."
                Import-Module RemoteDesktop
                return @{
                    Result = (Get-RDSessionCollection -ConnectionBroker $using:NodeNameFQDN -CollectionName $using:CollectionName).CollectionName
                }
            }
            TestScript = {
                $state = Invoke-Expression -Command $GetScript
                switch (($null -ne $state['Result']) -and ($state['Result'] -eq $using:CollectionName)) {
                    $true { return $true }
                    $false { return $false }
                }
            }
            SetScript = {
                Write-Verbose "Creating New Session Collection."
                Import-Module RemoteDesktop
                New-RDSessionCollection -CollectionName $using:CollectionName -SessionHost $using:NodeNameFQDN -ConnectionBroker $using:NodeNameFQDN
            }
            DependsOn = @("[WindowsFeature]RDS-Connection-Broker","[Script]RDSLicensingConfig")
        }
        xRDSessionCollectionConfiguration "RDSCollectionConfig" {
            CollectionName = $commonSettings.CollectionName
            ConnectionBroker = $Node.NodeNameFQDN
            AuthenticateUsingNLA = $false
            AutomaticReconnectionEnabled = $true
            BrokenConnectionAction = "Disconnect"
            ClientDeviceRedirectionOptions = "AudioVideoPlayBack, PlugAndPlayDevice, Clipboard, Drive"
            ClientPrinterAsDefault = $false
            DisconnectedSessionLimitMin = 120
            EncryptionLevel = "ClientCompatible"
            IdleSessionLimitMin = 120
            MaxRedirectedMonitors = 4
            RDEasyPrintDriverEnabled = $true
            SecurityLayer = "Negotiate"
            UserGroup = $commonSettings.CollectionUsers
            TemporaryFoldersDeletedOnExit = $true
            EnableUserProfileDisk = $false
            DependsOn = "[Script]RDSCollection"
        }
        #endregion RDS
        #region IIS
        $IISFeatures = @(
            "Web-WebServer",
            "Web-Common-Http",
            "Web-Default-Doc",
            "Web-Dir-Browsing",
            "Web-Http-Errors",
            "Web-Static-Content",
            "Web-Http-Redirect",
            "Web-DAV-Publishing",
            "Web-Health",
            "Web-Http-Logging",
            "Web-Custom-Logging",
            "Web-Log-Libraries",
            "Web-ODBC-Logging",
            "Web-Request-Monitor",
            "Web-Http-Tracing",
            "Web-Performance",
            "Web-Stat-Compression",
            "Web-Dyn-Compression",
            "Web-Security",
            "Web-Filtering",
            "Web-Basic-Auth",
            "Web-CertProvider",
            "Web-Client-Auth",
            "Web-Digest-Auth",
            "Web-Cert-Auth",
            "Web-IP-Security",
            "Web-Url-Auth",
            "Web-Windows-Auth",
            "Web-App-Dev",
            "Web-Net-Ext",
            "Web-Net-Ext45",
            "Web-AppInit",
            "Web-ASP",
            "Web-Asp-Net",
            "Web-Asp-Net45",
            "Web-CGI",
            "Web-ISAPI-Ext",
            "Web-ISAPI-Filter",
            "Web-Includes",
            "Web-WebSockets",
            "Web-Mgmt-Tools",
            "Web-Mgmt-Console",
            "Web-Mgmt-Compat",
            "Web-Metabase",
            "Web-Lgcy-Mgmt-Console",
            "Web-Lgcy-Scripting",
            "Web-WMI",
            "Web-Scripting-Tools",
            "Web-Mgmt-Service",
            "Web-WHC"
        )
        WindowsFeature IIS {
            Ensure                          = "Present"
            Name                            = "Web-Server"            
        }
        foreach ($IISFeature in $IISFeatures) {
            WindowsFeature "IIS-$($IISFeature)" {
                Ensure = "Present"
                Name = "$($IISFeature)"
                DependsOn = "[WindowsFeature]IIS"
            }
        }
        WindowsFeature dotNet35 {
            Ensure                          = "Present" 
            Name                            = "NET-Framework-Features"
            IncludeAllSubFeature            = $true 
            DependsOn                       = "[WindowsFeature]IIS"
            Source                          = "\\domain.com\folders\Apps\install_media\Microsoft\Windows Server 2019\sources\sxs"  
        }

        WindowsFeature dotNet45 {
            Ensure                          = "Present"
            Name                            = "NET-Framework-45-Features"
            DependsOn                       = "[WindowsFeature]IIS"
            IncludeAllSubFeature            = $true  
        }

        WindowsFeature dotNet45HTTPActivation {
            Ensure                          = "Present"
            Name                            = "NET-WCF-HTTP-Activation45"
            DependsOn                       = "[WindowsFeature]dotNet45"
        }

        WindowsFeature MSMQ {
            Ensure                          = "Present"
            Name                            = "MSMQ-Server"
            DependsOn                       = "[WindowsFeature]IIS"
        }
        
        $InetPubRoot                        = "C:\Inetpub"
        $InetPubLog                         = "C:\Inetpub\Log"
        $InetPubWWWRoot                     = "C:\Inetpub\WWWRoot"
        $ServiceSiteRoot                    = "C:\Inetpub\ServiceRoot"
        $APISiteRoot                        = "C:\Inetpub\APIRoot"
        $WebAPIRoot                 = "C:\Inetpub\APIRoot\WebAPI"
        $ServiceRoot                = "C:\Inetpub\ServiceRoot\Service"
        $IISDirs = @(
            $InetPubRoot,
            $InetPubLog,
            $InetPubWWWRoot,
            $ServiceSiteRoot,
            $APISiteRoot,
            $WebAPIRoot,
            $ServiceRoot,
            "C:\Inetpub\temp",
            "C:\Inetpub\temp\apppools",
            "C:\scripts\",
            "C:\scripts\iisPerformancesettings\"
        )
        foreach ($IISDir in $IISDirs) {
            File "IISDir-$($IISDir)"
            {
                Ensure                      = "Present"
                Type                        = "Directory"
                DestinationPath             = "$($IISDir)"
                DependsOn                   = "[WindowsFeature]IIS"
            }
        }
        File "randomtxtfile" {
            Ensure                          = "Present"
            Type                            = "File"
            DestinationPath                 = "C:\scripts\iisPerformancesettings\log1-1.txt"
            Contents                        = "" 
        }
        File "PromoFolder" {
            Ensure                          = "Present"
            Type                            = "Directory"
            SourcePath                      = "$($commonSettings.FileServerPath)\WWPromos\Revisions\201903\Promos"
            DestinationPath                 = "C:\Inetpub\ServiceRoot\Promos"
            MatchSource                     = $true
            Recurse                         = $true
            CheckSum                        = "SHA-256"
        }
        PfxImport pfx {
            Thumbprint                      = "ECDB91B3A55AAF82B5A624FD4B26F28ED093BD78"
            Path                            = "$($commonSettings.CertFilePath)"
            Location                        = 'LocalMachine'
            Store                           = 'WebHosting'
            Credential                      = $PFXCreds
        }
        cNtfsPermissionEntry "InetPubWWWRootACL_IISUSRS" {
            Ensure                          = 'Present'
            Path                            = $InetPubWWWRoot
            Principal                       = "BUILTIN\IIS_IUSRS"
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType       = "Allow"
                    FileSystemRights        = "ReadAndExecute"
                    Inheritance             = "ThisFolderSubfoldersAndFiles"
                    NoPropagateInherit      = $false   
                }
            )
        }
        cNtfsPermissionEntry "InetPubWWWRootACL_Users" {
            Ensure                          = 'Present'
            Path                            = $InetPubWWWRoot
            Principal                       = "BUILTIN\Users"
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType       = "Allow"
                    FileSystemRights        = "ReadAndExecute"
                    Inheritance             = "ThisFolderSubfoldersAndFiles"
                    NoPropagateInherit      = $false   
                }
            )
            DependsOn                       = "[WindowsFeature]IIS"
        }
        cNtfsPermissionEntry "InetpubLogACL_TrustedInstaller" {
            Ensure                          = 'Present'
            Path                            = $InetPubWWWRoot
            Principal                       = "NT SERVICE\TrustedInstaller"
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType           = "Allow"
                    FileSystemRights            = "FullControl"
                    Inheritance                 = "ThisFolderSubfoldersAndFiles"
                    NoPropagateInherit          = $false   
                }
            )
            DependsOn                       = "[WindowsFeature]IIS"
        }
        xWebsite "enableBasicAuth" {
            Name                            = "Default Web Site"
            AuthenticationInfo              = MSFT_xWebAuthenticationInformation
            {
                Anonymous                   = $false
                Basic                       = $true
                Windows                     = $true
                Digest                      = $false
            }
        }
        xIisLogging logLocation 
        {
            LogPath                         = "C:\Inetpub\Log"
        }
        Script "removeDefaultWebBinding" {
            GetScript = {
                $Ensure = 'Absent'
                if (Get-WebBinding -Port 443 -Name "Default Web Site") {
                    $ensure = 'Present'
                } else {
                    $ensure = 'Absent'
                }
                $result = @{
                    SourceName = $SourceName
                    Ensure = $ensure
                }
                return $result 
            }
            TestScript = {
                $Ensure = 'Absent'
                $state = [scriptblock]::Create($GetScript).Invoke()
                return $state.Ensure -eq $Ensure
            }
            SetScript = {
                Get-WebBinding -Port 443 -Name "Default Web Site" | Remove-WebBinding
            }
            DependsOn = "[xWebsite]enableBasicAuth"
        }
        xWebAppPool "create_Service" {
            Ensure                          = "Present"
            Name                            = "Service"
            enable32BitAppOnWin64           = $false
            managedRuntimeVersion           = "v4.0"
            restartPrivateMemoryLimit       = "1048576"
            identityType                    = "NetworkService"
            idleTimeout                     = (New-TimeSpan -Minutes 120).ToString()
            restartTimeLimit                = "00:00:00" 
            restartSchedule                 = "04:00:00"
            DependsOn                       = "[WindowsFeature]IIS"
        }
        xWebsite "create_ServiceSite" {
            Ensure                          = "Present"
            Name                            = "ServiceSite"
            PhysicalPath                    = $ServiceSiteRoot
            BindingInfo                     = MSFT_xWebBindingInformation
            {
                Protocol                    = "http"
                IPAddress                   = "*"
                Port                        = "8080"
            }
            AuthenticationInfo              = MSFT_xWebAuthenticationInformation
            {
                Anonymous                   = $true
                Basic                       = $true
                Windows                     = $true
                Digest                      = $false
            }
            ApplicationPool                 = "Service"
            DependsOn                       = "[xWebAppPool]create_Service" 
        }
        xWebApplication "create_Service" {
            Ensure                          = "Present"
            Name                            = "Service"
            WebAppPool                      = "Service"
            PhysicalPath                    = $ServiceRoot
            Website                         = "ServiceSite" 
            DependsOn                       = "[xWebsite]create_ServiceSite" 
        }
        xWebAppPool "create_API" {
            Ensure                          = "Present"
            Name                            = "API"
            enable32BitAppOnWin64           = $false
            managedRuntimeVersion           = "v4.0"
            restartPrivateMemoryLimit       = "1048576"
            identityType                    = "LocalSystem"
            idleTimeout                     = (New-TimeSpan -Minutes 120).ToString()
            restartTimeLimit                = "00:00:00" 
            restartSchedule                 = "04:00:00"
            DependsOn                       = "[WindowsFeature]IIS"
        }
        xWebsite "create_APISite" {
            Ensure                          = "Present"
            Name                            = "APISite"
            PhysicalPath                    = $APISiteRoot
            BindingInfo                     = MSFT_xWebBindingInformation
            {
                Protocol                    = "https"
                IPAddress                   = "*"
                Port                        = "443"
                CertificateThumbprint       = "ECDB91B3A55AAF82B5A624FD4B26F28ED093BD78"
                CertificateStoreName        = "WebHosting" 
            }
            AuthenticationInfo              = MSFT_xWebAuthenticationInformation
            {
                Anonymous                   = $true
                Basic                       = $false
                Windows                     = $false
                Digest                      = $false
            }
            ApplicationPool                 = "API"
            DependsOn                       = @("[xWebAppPool]create_API","[PfxImport]wwpfx","[Script]removeDefaultWebBinding")
        }
        xWebApplication "create_WebAPI" {
            Ensure                          = "Present"
            Name                            = "WebAPI"
            WebAppPool                      = "API"
            PhysicalPath                    = $WebAPIRoot
            Website                         = "APISite" 
            DependsOn                       = "[xWebsite]create_APISite" 
        }
        #region Not sure we need these mimetypes, at least on Server 2019
        <#
        xIisMimeTypeMapping json
        {
            Ensure                          = "Present"
            Extension                       = ".json"
            MimeType                        = "application/json"
            ConfigurationPath               = 'IIS:\Sites\Default Web Site\'
            DependsOn                       = "[WindowsFeature]IIS"
        }
        xIisMimeTypeMapping svg
        {
            Ensure                          = "Present"
            Extension                       = ".svg"
            MimeType                        = "image/svg+xml"
            ConfigurationPath               = 'IIS:\Sites\Default Web Site\'
            DependsOn                       = "[WindowsFeature]IIS"
        }
        xIisMimeTypeMapping woff
        {
            Ensure                          = "Present"
            Extension                       = ".woff"
            MimeType                        = "application/x-font-woff"
            ConfigurationPath               = 'IIS:\Sites\Default Web Site\'
            DependsOn                       = "[WindowsFeature]IIS"
        }
        xIisMimeTypeMapping woff2
        {
            Ensure                          = "Present"
            Extension                       = ".woff2"
            MimeType                        = "application/font-woff2"
            ConfigurationPath               = 'IIS:\Sites\Default Web Site\'
            DependsOn                       = "[WindowsFeature]IIS"
        }
        #>
        #endregion Not sure we need these mimetypes, at least on Server 2019
        Script "create_ServiceEventSource" {
            GetScript = {
                $Ensure = 'Present'
                $SourceName = 'Service'
                if ([System.Diagnostics.EventLog]::SourceExists($SourceName)) {
                    $ensure = 'Present'
                } else {
                    $ensure = 'Absent'
                }
            
                $result = @{
                    SourceName = $SourceName
                    Ensure = $ensure
                }
                return $result 
            }
            TestScript = {
                $Ensure = 'Present'
                $state = [scriptblock]::Create($GetScript).Invoke()
                return $state.Ensure -eq $Ensure
            }
            SetScript = {
                $SourceName = 'Service'
                $LogName = 'Application'

                Write-Verbose -Message "Creating event source '$SourceName', log '$LogName'."
                [System.Diagnostics.EventLog]::CreateEventSource($SourceName, $LogName)
                Write-EventLog –LogName $LogName –Source $SourceName –EntryType Information –EventID 1 –Message "${SourceName} event source created"
            }
            DependsOn = "[xWebAppPool]create_Service"
        }
        Script "create_EventSource" {
            GetScript = {
                $Ensure = 'Present'
                $SourceName = ''
                if ([System.Diagnostics.EventLog]::SourceExists($SourceName)) {
                    $ensure = 'Present'
                } else {
                    $ensure = 'Absent'
                }
            
                $result = @{
                    SourceName = $SourceName
                    Ensure = $ensure
                }
            
                return $result 
            }
            TestScript = {
                $Ensure = 'Present'
                $state = [scriptblock]::Create($GetScript).Invoke()
                return $state.Ensure -eq $Ensure
            }
            SetScript = {
                $SourceName = ''
                $LogName = 'Application'

                Write-Verbose -Message "Creating event source '$SourceName', log '$LogName'."
                [System.Diagnostics.EventLog]::CreateEventSource($SourceName, $LogName)
                Write-EventLog –LogName $LogName –Source $SourceName –EntryType Information –EventID 1 –Message "${SourceName} event source created"
            }
        }
        Registry IISRemoteMgmt {
            Ensure                          = "Present" 
            Key                             = "HKLM:\SOFTWARE\Microsoft\WebManagement\Server"
            ValueName                       = "EnableRemoteManagement"
            ValueData                       = "1"
            ValueType                       = "Dword"
            DependsOn                       = "[WindowsFeature]IIS"
            Force                           = $true
        }
        #endregion IIS
        #region Local Group Management
        Group ServerManagers {
            Ensure = 'Present'
            GroupName = 'Server Managers'
            Members = "domain\$($commonSettings.ServerNumber)_mgr"
            Credential = $ADCreds
        }
        #endregion
        #region Files and Shares
        WindowsFeature FS-FileServer { 
            Ensure = "Present" 
            Name = "FS-FileServer" 
        }
        WindowsFeature Storage-Services { 
            Ensure = "Present" 
            Name = "Storage-Services" 
        }
        WaitForDisk Disk2 {
            DiskId = 1
            DiskIdType = 'Number'
            RetryCount = 30
            RetryIntervalSec = 60
            DependsOn = @("[WindowsFeature]FS-FileServer", "[WindowsFeature]Storage-Services")
        }
        Disk HDisk {
            DiskId = 1
            DiskIdType = 'Number'
            DriveLetter = 'H'
            ClearDisk = $true
            FSFormat = 'NTFS'
            PartitionStyle = 'GPT'
            DependsOn = "[WaitForDisk]Disk2"
        }
        File HData {
            Ensure = 'Present'
            Type = "Directory"
            DestinationPath = 'H:\Data'
            DependsOn = "[Disk]HDisk"
        }
        File HDataPublic {
            Ensure = 'Present'
            Type = "Directory"
            DestinationPath = 'H:\Data\Public'
            DependsOn = "[File]HData"
        }
        File HDataManagers {
            Ensure = 'Present'
            Type = "Directory"
            DestinationPath = 'H:\Data\Managers'
            DependsOn = "[File]HData"
        }
        # Remove permission inheritance on h:\data\managers.
        cNtfsPermissionsInheritance removeManagersInheritance {
            Path = 'H:\Data\Managers'
            Enabled = $false
            PreserveInherited = $false
            DependsOn = '[File]HDataManagers'
        }
        # Set explicit permissions on h:\data\managers   administrators: full control   ‘Server Managers’ local group read/write
        cNtfsPermissionEntry managersServerManagersReadWrite {
            Ensure = 'Present'
            Path = 'H:\Data\Managers'
            Principal = 'Server Managers'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
            DependsOn = '[cNtfsPermissionsInheritance]removeManagersInheritance'
        }
        cNtfsPermissionEntry managersAdministratorsFullControl {
            Ensure = 'Present'
            Path = 'H:\Data\Managers'
            Principal = 'BUILTIN\Administrators'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'FullControl'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
            DependsOn = '[cNtfsPermissionsInheritance]removeManagersInheritance'
        }
        cNtfsPermissionEntry publicUsersReadWrite {
            Ensure = 'Present'
            Path = 'H:\Data\Public'
            Principal = 'BUILTIN\Users'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
            DependsOn = '[File]HDataPublic'
        }
        SmbShare 'DataShare' {
            Ensure = 'Present'
            Name = 'Data'
            Path = 'H:\Data'
            Description = 'Data Share'
            FullAccess = @('Everyone')
            DependsOn = "[File]HData"
            CachingMode = 'None'
        }
        File CreateDesktopFolder {
            Ensure = 'Present'
            Type = "Directory"
            DestinationPath = "C:\Windows\SysWOW64\config\systemprofile\Desktop"
        }
        #endregion
        #region PowerSettings
        PowerPlan Highperf {
            IsSingleInstance = 'Yes'
            Name             = 'High Performance'
        }
        #endregion
    }
} 

<#
#region Manual Run
$startLocation = Get-Location
Push-Location (Split-Path $script:MyInvocation.MyCommand.Path)
$configData = Import-PowerShellDataFile -Path $PathToConfigurationFile
if (Test-Path -Path C:\temp)
{
    Server_SingleNode -ConfigurationData $configData -OutputPath C:\temp
}
else 
{
    Write-Output "C:\temp doesn't exist. Creating..."
    try {
        New-Item -Path C:\temp
    }
    catch {
        Write-Output "Unable to create C:\temp. Exiting."
        Write-Output "$($Error[0].Exception)"
        Exit
    }
    if (Test-Path -Path C:\temp)
    {
        Write-Output "C:\temp was created. Continuing..."
        Server_SingleNode -ConfigurationData $configData -OutputPath c:\temp
    }
}
$Nodes = ($configData.AllNodes.where{$_.Role -eq 'SessionHost'}).NodeName
#Start-DscConfiguration -Path C:\temp\Server_SingleNode -ComputerName $Nodes #-Wait -Verbose

Push-Location $startLocation
#endregion 
#>


