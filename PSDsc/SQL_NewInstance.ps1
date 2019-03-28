Configuration NewSQLInstance
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential = $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServiceCredential,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServiceCredential = $SqlServiceCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc' -ModuleVersion 12.3.0.0
    Import-DscResource -ModuleName 'NetworkingDsc' -ModuleVersion 7.0.0.0
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node $AllNodes.Where{$_.Role -eq 'DBServer'}.NodeName
    {
        $commonSettings = $ConfigurationData[$Node.CommonConfig]
        $instanceSettings = $ConfigurationData[$Node.SQLInstance]
        $ssrsSettings = $ConfigurationData[$Node.SSRS]
        #region Install SQL Server
        IPAddress NodeIPAddress
        {
            AddressFamily = "IPv4"
            InterfaceAlias = $Node.InterfaceAlias
            IPAddress = $Node.IPAddress
            KeepExistingAddress = $false
        }
        DefaultGatewayAddress GatewayIP
        {
            AddressFamily = "IPv4"
            InterfaceAlias = $Node.InterfaceAlias
            Address = $commonSettings.GateWay
            DependsOn = "[IPAddress]NodeIPAddress"
        }
        DnsServerAddress DNSServerAddresses
        {
            AddressFamily = "IPv4"
            InterfaceAlias = $Node.InterfaceAlias
            Address = "$($commonSettings.DNSServer1)","$($commonSettings.DNSServer2)","$($commonSettings.DNSServer3)"
            Validate = $true
            DependsOn = "[DefaultGatewayAddress]GatewayIP"
        }
        DnsConnectionSuffix DnsConnectionSuffixConfig
        {
            Ensure = 'Present'
            InterfaceAlias = $Node.InterfaceAlias
            ConnectionSpecificSuffix = $commonSettings.ConnectionSpecificSuffix
            RegisterThisConnectionsAddress = $true
            DependsOn = "[DnsServerAddress]DNSServerAddresses"
        }
        SqlSetup InstallInstance
        {
            InstanceName           = $instanceSettings.InstanceName
            Features               = $instanceSettings.Features
            SQLCollation           = $instanceSettings.SQLCollation
            SQLSvcAccount          = $SqlServiceCredential
            AgtSvcAccount          = $SqlAgentServiceCredential
            SQLSysAdminAccounts    = 'domain\DBAdmins', $SqlAdministratorCredential.UserName
            InstallSharedDir       = $instanceSettings.InstallSharedDir
            InstallSharedWOWDir    = $instanceSettings.Installshared
            InstanceDir            = $instanceSettings.InstanceDir
            InstallSQLDataDir      = $instanceSettings.InstallSQLDataDir
            SQLUserDBDir           = $instanceSettings.SQLUserDBLogDir
            SQLUserDBLogDir        = $instanceSettings.SQLUserDBLogDir
            SQLTempDBDir           = $instanceSettings.SQLTempDBDir
            SQLTempDBLogDir        = $instanceSettings.SQLTempDBLogDir
            SQLBackupDir           = $instanceSettings.SQLBackupDir
            SourcePath             = $instanceSettings.SourcePath
            UpdateEnabled          = 'False'
            ForceReboot            = $false
            SqlTempdbFileCount     = 4
            SqlTempdbFileSize      = 1024
            SqlTempdbFileGrowth    = 512
            SqlTempdbLogFileSize   = 128
            SqlTempdbLogFileGrowth = 64
            PsDscRunAsCredential   = $SqlInstallCredential
            DependsOn              = '[DnsConnectionSuffix]DnsConnectionSuffixConfig'
        }
        #endregion Install SQL Server
        SqlWindowsFirewall FireWallInboundSQLRules
        {
            Ensure          = 'Present'
            Features        = $instanceSettings.Features
            InstanceName    = $instanceSettings.InstanceName
            SourcePath      = $instanceSettings.SourcePath 
            PsDscRunAsCredential = $SqlAdministratorCredential
            DependsOn = '[SqlSetup]InstallInstance'
        }
        SqlServerMaxDop Set_SQLServerMaxDop
        {
            Ensure               = 'Present'
            DynamicAlloc         = $false
            MaxDop               = 1
            ServerName           = $Node.NodeNameFQDN
            InstanceName         = $instanceSettings.InstanceName
            PsDscRunAsCredential = $SqlAdministratorCredential
            DependsOn = '[SqlSetup]InstallInstance'
        }
        SqlServerMemory Set_SQLServerMaxMemory
        {
            Ensure               = 'Present'
            DynamicAlloc         = $false
            MinMemory            = $instanceSettings.MinMemory
            MaxMemory            = $instanceSettings.MaxMemory
            ServerName           = $Node.NodeNameFQDN
            InstanceName         = $instanceSettings.InstanceName
            PsDscRunAsCredential = $SqlAdministratorCredential
            DependsOn = '[SqlSetup]InstallInstance'
        }
        Package SSRS2017
        {
            Ensure = 'Present'
            Name = "Microsoft SQL Server Reporting Services"
            Path = $ssrsSettings.Path
            ProductId = 'ProductID'
            Arguments = "/quiet /norestart /IAcceptLicenseTerms /PID $($ssrsSettings.SSRSPID)"
        }
        SqlRS DefaultConfiguration
        {
            InstanceName         = $ssrsSettings.DBInstance
            DatabaseServerName   = $ssrsSettings.DBHostName
            DatabaseInstanceName = $ssrsSettings.DBInstance
            DependsOn = '[Package]SSRS2017'
        }
    }
}