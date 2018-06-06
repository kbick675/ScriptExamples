param
(
    [Parameter()]
    [System.String[]]
    $NodeName = 'localhost'
)

Configuration NewOOSFarm 
{

    Import-DscResource -ModuleName 'OfficeOnlineServerDsc' -ModuleVersion 1.2.0.0
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion 8.0.0.0

    Node $AllNodes.Where{ $_.Role -eq "FirstOOSNode" }.NodeName
    {
        $netcorefeatures = @(
            "NET-Framework-Features",
            "NET-Framework-Core",
            "NET-HTTP-Activation"
        )
        $requiredFeatures = @(
            "Web-Server",
            "Web-Mgmt-Tools",
            "Web-Mgmt-Console",
            "Web-WebServer",
            "Web-Common-Http",
            "Web-Default-Doc",
            "Web-Static-Content",
            "Web-Performance",
            "Web-Stat-Compression",
            "Web-Dyn-Compression",
            "Web-Security",
            "Web-Filtering",
            "Web-Windows-Auth",
            "Web-App-Dev",
            "Web-Net-Ext45",
            "Web-Asp-Net45",
            "Web-ISAPI-Ext",
            "Web-ISAPI-Filter",
            "Web-Includes",
            "NET-Framework-45-Features",
            "NET-Framework-45-Core",
            "NET-Non-HTTP-Activ",
            "NET-WCF-HTTP-Activation45",
            "Windows-Identity-Foundation",
            "Server-Media-Foundation"
        )
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
        File OOSBinaries
        {
            Ensure = "Present"
            SourcePath = '\\path\to\packages\installers\microsoft\Office Online Server\Setup'
            DestinationPath = "C:\Installer"
            Recurse = $true
            Type = "Directory"
            MatchSource = $true
        }
        foreach ($netcorefeature in $netcorefeatures)
        {
            WindowsFeature "WindowsFeature-$netcorefeature"
            {
                Ensure = 'Present'
                Name   = $netcorefeature
                Source = "\\path\to\extracted\iso\2016\setup\sources\sxs"
            }
        }
        foreach ($feature in $requiredFeatures)
        {
            WindowsFeature "WindowsFeature-$feature"
            {
                Ensure = 'Present'
                Name   = $feature
            }
        }

        $prereqDependencies = $RequiredFeatures | ForEach-Object -Process {
            return "[WindowsFeature]WindowsFeature-$_"
        }
        xPackage MSIdentityExtensions
        {
            Ensure="Present"
            Name = "Microsoft Identity Extensions"
            Path = "C:\Installer\MicrosoftIdentityExtensions-64.msi"
            Arguments = '/quiet /norestart'
            ProductId = 'F99F24BF-0B90-463E-9658-3FD2EFC3C992'
            DependsOn = $prereqDependencies
        }
        xPackage vc_redist2013
        {
            Ensure="Present"
            Name = "Microsoft Visual C++ 2013 x64 Minimum Runtime - 12.0.21005"
            Path = "C:\Installer\vcredist_x64.exe"
            Arguments = '/install /passive /norestart'
            ProductId = 'A749D8E6-B613-3BE3-8F5F-045C84EBA29B'
        }
        xPackage vc_redist2015
        {
            Ensure="Present"
            Name = "Microsoft Visual C++ 2015 x64 Minimum Runtime - 14.0.23026"
            Path = "C:\Installer\vc_redist.x64.exe"
            Arguments = '/install /passive /norestart'
            ProductId = '0D3E9E15-DE7A-300B-96F1-B4AF12B96488'
        }
        OfficeOnlineServerInstall InstallBinaries
        {
            Path      = "C:\Installer\setup.exe"
            Ensure = "Present"
            DependsOn = "[xPackage]MSIdentityExtensions"
        }

        OfficeOnlineServerFarm oosspacexcom
        {
            InternalURL     = $Node.InternalURL
            ExternalURL     = $Node.ExternalURL 
            EditingEnabled  = $Node.EditingEnabled
            AllowCEIP       = $Node.AllowCEIP
            AllowHttp       = $Node.AllowHTTP
            AllowHttpSecureStoreConnections = $Node.AllowHttpSecureStoreConnections
            AllowOutboundHttp = $Node.AllowOutboundHttpout
            CertificateName = $Node.CertificateName
            SSLOffloaded    = $Node.SSLOffloaded
            OpenFromUncEnabled = $Node.OpenFromUncEnabled
            OpenFromUrlEnabled = $Node.OpenFromUrlEnabled
            OpenFromUrlThrottlingEnabled = $Node.OpenFromUrlThrottlingEnabled
        }
    }

    Node $AllNodes.Where{ $_.Role -eq "OOSMember" }.NodeName
    {
        $netcorefeatures = @(
            "NET-Framework-Features",
            "NET-Framework-Core",
            "NET-HTTP-Activation"
        )
        $requiredFeatures = @(
            "Web-Server",
            "Web-Mgmt-Tools",
            "Web-Mgmt-Console",
            "Web-WebServer",
            "Web-Common-Http",
            "Web-Default-Doc",
            "Web-Static-Content",
            "Web-Performance",
            "Web-Stat-Compression",
            "Web-Dyn-Compression",
            "Web-Security",
            "Web-Filtering",
            "Web-Windows-Auth",
            "Web-App-Dev",
            "Web-Net-Ext45",
            "Web-Asp-Net45",
            "Web-ISAPI-Ext",
            "Web-ISAPI-Filter",
            "Web-Includes",
            "NET-Framework-45-Features",
            "NET-Framework-45-Core",
            "NET-Non-HTTP-Activ",
            "NET-WCF-HTTP-Activation45",
            "Windows-Identity-Foundation",
            "Server-Media-Foundation"
        )
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
        File OOSBinaries
        {
            Ensure = "Present"
            SourcePath = '\\path\to\packages\installers\microsoft\Office Online Server\Setup'
            DestinationPath = "C:\Installer"
            Recurse = $true
            Type = "Directory"
            MatchSource = $true
        }
        foreach ($netcorefeature in $netcorefeatures)
        {
            WindowsFeature "WindowsFeature-$netcorefeature"
            {
                Ensure = 'Present'
                Name   = $netcorefeature
                Source = "\\path\to\extracted\iso\2016\setup\sources\sxs"
            }
        }
        foreach ($feature in $requiredFeatures)
        {
            WindowsFeature "WindowsFeature-$feature"
            {
                Ensure = 'Present'
                Name   = $feature
            }
        }
        
        $prereqDependencies = $RequiredFeatures | ForEach-Object -Process {
            return "[WindowsFeature]WindowsFeature-$_"
        }
    
        xPackage MSIdentityExtensions
        {
            Ensure="Present"
            Name = "Microsoft Identity Extensions"
            Path = "C:\Installer\MicrosoftIdentityExtensions-64.msi"
            Arguments = '/quiet /norestart'
            ProductId = 'F99F24BF-0B90-463E-9658-3FD2EFC3C992'
            DependsOn = $prereqDependencies
        }
        xPackage vc_redist2013
        {
            Ensure="Present"
            Name = "Microsoft Visual C++ 2013 x64 Minimum Runtime - 12.0.21005"
            Path = "C:\Installer\vcredist_x64.exe"
            Arguments = '/install /passive /norestart'
            ProductId = 'A749D8E6-B613-3BE3-8F5F-045C84EBA29B'
        }
        xPackage vc_redist2015
        {
            Ensure="Present"
            Name = "Microsoft Visual C++ 2015 x64 Minimum Runtime - 14.0.23026"
            Path = "C:\Installer\vc_redist.x64.exe"
            Arguments = '/install /passive /norestart'
            ProductId = '0D3E9E15-DE7A-300B-96F1-B4AF12B96488'
        }
        OfficeOnlineServerInstall InstallBinaries
        {
            Path      = "C:\Installer\setup.exe"
            Ensure = "Present"
            DependsOn = "[xPackage]MSIdentityExtensions"
        }
        OfficeOnlineServerMachine JoinFarm
        {
            MachineToJoin = $AllNodes.Where{ $_.Role -eq "FirstOOSNode" }.NodeFQDN
            Ensure = 'Present'
            Roles = "All"
            DependsOn = "[OfficeOnlineServerInstall]InstallBinaries"
        }
    }
}

$StartingLocation = Get-Location

Push-Location \\path\to\dsc\runpath

NewOOSFarm -ConfigurationData '\\path\to\DSC\OOS_oos.spacex.com.psd1'
#Set-DscLocalConfigurationManager -Path .\NewOOSFarm -ComputerName $NodeName
#Start-DscConfiguration -Path .\NewOOSFarm -ComputerName $NodeName
Push-Location $StartingLocation