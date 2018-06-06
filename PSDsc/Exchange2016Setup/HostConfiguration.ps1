param
(
    [Parameter()]
    [System.String[]]
    $NodeName = 'localhost',
    [switch]$NoInitialConfig,
    [switch]$NoNetwork
)
Configuration InitialConfiguration
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Node $NodeName
    {
        LocalConfigurationManager
        {
            CertificateId      = $Node.Thumbprint
            RebootNodeIfNeeded = $true
        }
        File PublicKey
        {
            Ensure = "Present"
            SourcePath = "\\path\to\PS\DSC\certificates\DSCpub.cer"
            DestinationPath = "C:\PKI\DSCpub.cer"
            Type = "File"
            MatchSource = $true
        }
        File PrivateKey
        {
            Ensure = "Present"
            SourcePath = "\\path\to\PS\DSC\certificates\DSCprivatekey.pfx"
            DestinationPath = "C:\PKI\DSCprivatekey.pfx"
            Type = "File"
            MatchSource = $true
        }
        File dsccertenigmakey
        {
            Ensure = "Present"
            SourcePath = "\\path\to\PS\DSC\Certificates\key.txt"
            DestinationPath = "C:\Deployment\key.txt"
            Type = "File"
            MatchSource = $true
        }
        File xExchange
        {
            Ensure = 'Present'
            SourcePath = "\\path\to\PS\Modules\xExchange\1.19.0.0"
            DestinationPath = 'C:\Program Files\WindowsPowerShell\Modules\xExchange\1.19.0.0'
            Type = 'Directory'
            Recurse = $true
            MatchSource = $true
        }
        File xCertificate
        {
            Ensure = 'Present'
            SourcePath = "\\path\to\PS\Modules\xCertificate\3.2.0.0"
            DestinationPath = "C:\Program Files\WindowsPowerShell\Modules\xCertificate\3.2.0.0"
            Type = 'Directory'
            Recurse = $true
            MatchSource = $true
        }
        File xNetworking
        {
            Ensure = 'Present'
            SourcePath = "\\path\to\PS\Modules\xNetworking\5.4.0.0"
            DestinationPath = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking\5.4.0.0'
            Type = 'Directory'
            Recurse = $true
            MatchSource = $true
        }
        File xWebAdministration
        {
            Ensure = 'Present'
            SourcePath = "\\path\to\PS\Modules\xWebAdministration\1.19.0.0"
            DestinationPath = 'C:\Program Files\WindowsPowerShell\Modules\xWebAdministration\1.19.0.0'
            Type = 'Directory'
            Recurse = $true
            MatchSource = $true
        }
        File xPendingReboot
        {
            Ensure = 'Present'
            SourcePath = "\\path\to\PS\Modules\xPendingReboot\0.3.0.0"
            DestinationPath = 'C:\Program Files\WindowsPowerShell\Modules\xPendingReboot\0.3.0.0'
            Type = 'Directory'
            Recurse = $true
            MatchSource = $true
        }
        File xPSDesiredStateConfiguration
        {
            Ensure = 'Present'
            SourcePath = "\\path\to\PS\Modules\xPSDesiredStateConfiguration\8.0.0.0"
            DestinationPath = 'C:\Program Files\WindowsPowerShell\Modules\xPSDesiredStateConfiguration\8.0.0.0'
            Type = 'Directory'
            Recurse = $true
            MatchSource = $true
        }
        File PSDscResources
        {
            Ensure = 'Present'
            SourcePath = "\\path\to\PS\Modules\PSDscResources\2.8.0.0"
            DestinationPath = 'C:\Program Files\WindowsPowerShell\Modules\PSDscResources\2.8.0.0'
            Type = 'Directory'
            Recurse = $true
            MatchSource = $true
        }
        File dotnetfiles
        {
            Ensure = "Present"
            SourcePath = "\\path\to\packages\Installers\Microsoft\dotnet471offline\NDP471-KB4033342-x86-x64-AllOS-ENU.exe"
            DestinationPath = "C:\SetupBinaries\dotnet\NDP471-KB4033342-x86-x64-AllOS-ENU.exe"
            Type = "File"
            MatchSource = $true
        }
        File UCMAFiles
        {
            Ensure = "Present"
            SourcePath = "\\path\to\packages\Installers\Microsoft\Exchange 2016 Enterprise\Prereqs\UcmaRuntimeSetup.exe"
            DestinationPath = "C:\SetupBinaries\UCMA\UcmaRuntimeSetup.exe"
            Type = "File"
            MatchSource = $true
        }
        #Copy the Exchange setup files locally
        File ExchangeBinaries
        {
            Ensure          = 'Present'
            Type            = 'Directory'
            Recurse         = $true
            SourcePath      = '\\path\to\packages\Installers\Microsoft\Exchange 2016 Enterprise\CU8'
            DestinationPath = 'C:\SetupBinaries\E16CU8'
            MatchSource     = $true
        }

        $requiredFeatures = @(
            "NET-Framework-45-Features",
            "NET-WCF-HTTP-Activation45",
            "RPC-over-HTTP-proxy",
            "RSAT-Clustering",
            "RSAT-Clustering-CmdInterface",
            "RSAT-Clustering-Mgmt",
            "RSAT-Clustering-PowerShell",
            "WAS-Process-Model",
            "Web-Asp-Net45",
            "Web-Basic-Auth",
            "Web-Client-Auth",
            "Web-Digest-Auth",
            "Web-Dir-Browsing",
            "Web-Dyn-Compression",
            "Web-Http-Errors",
            "Web-Http-Logging",
            "Web-Http-Redirect",
            "Web-Http-Tracing",
            "Web-ISAPI-Ext",
            "Web-ISAPI-Filter",
            "Web-Lgcy-Mgmt-Console",
            "Web-Metabase",
            "Web-Mgmt-Console",
            "Web-Mgmt-Service",
            "Web-Net-Ext45",
            "Web-Request-Monitor",
            "Web-Server",
            "Web-Stat-Compression",
            "Web-Static-Content",
            "Web-Windows-Auth",
            "Web-WMI",
            "Windows-Identity-Foundation",
            "Failover-clustering",
            "RSAT-ADDS"
        )
        foreach ($feature in $requiredFeatures)
        {
            WindowsFeature "WindowsFeature-$feature"
            {
                Ensure = 'Present'
                Name   = $feature
            }
        }
        Script InstalldotNet
        {
            GetScript = {
                Write-Verbose "[Get].net Release"
                return @{
                    Result = [string](Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' -Name Release).Release
                    }
            }
            SetScript = {
                #Write-Verbose "[Set].net installation"
                Invoke-Command -ScriptBlock {cmd.exe /c "C:\SetupBinaries\dotnet\NDP471-KB4033342-x86-x64-AllOS-ENU.exe /q"}
            }
            TestScript = {
                Write-Verbose "[Test].net Release"
                $result = $GetScript
                Write-Verbose "[Test].net Release is $($result)"
                if ($result -eq '461310')
                {
                    return $true
                }
                elseif ($result -ne '461310')
                {
                    return $false
                }
            }
            DependsOn = '[File]dotnetfiles'
        }
        Package UCMA
        {
            Name = 'Microsoft Unified Communications Managed API 4.0, Runtime'
            Path = "C:\SetupBinaries\UCMA\UcmaRuntimeSetup.exe"
            ProductId = '41D635FE-4F9D-47F7-8230-9B29D6D42D31'
            Ensure = 'Present'
            Arguments = '-q'
            DependsOn = '[File]UCMAFiles'
        }
    }
}
Configuration SetupNicTeam
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking -ModuleVersion 5.4.0.0

    Node $NodeName
    {
        xNetworkTeam HostTeam
        {
            Name = 'Access'
            TeamingMode = 'SwitchIndependent'
            LoadBalancingAlgorithm = 'Dynamic'
            TeamMembers = 'Embedded FlexibleLOM 1 Port 1','Embedded FlexibleLOM 1 Port 2'
            Ensure = 'Present'
        }
        xDHCPClient DisableDhcpNicTeam1
        {
            State = 'Disabled'
            InterfaceAlias = 'Access'
            AddressFamily = 'IPv4'
            DependsOn = '[xNetworkTeam]HostTeam'
        }
        xDHCPClient DisableDhcpLomPort1
        {
            State = 'Disabled'
            InterfaceAlias = 'Embedded LOM 1 Port 1'
            AddressFamily = 'IPv4'
        }
        xDHCPClient DisableDhcpLomPort2
        {
            State = 'Disabled'
            InterfaceAlias = 'Embedded LOM 1 Port 2'
            AddressFamily = 'IPv4'
        }
        xIPAddress AccessVlanIP
        {
            IPAddress = $Node.IPAddress2000
            InterfaceAlias = 'Access'
            AddressFamily = 'IPv4'
            DependsOn = '[xNetworkTeam]HostTeam'
        }
        xDefaultGatewayAddress SetDefaultGateway
        {
            Address        = '10.34.0.1'
            InterfaceAlias = 'Access'
            AddressFamily  = 'IPv4'
            DependsOn = '[xIPAddress]AccessVlanIP'
        }
        xDnsServerAddress DnsServerAddress
        {
            Address        = '10.1.32.10','10.1.32.11'
            InterfaceAlias = 'Access'
            AddressFamily  = 'IPv4'
            Validate       = $false
            DependsOn = '[xDefaultGatewayAddress]SetDefaultGateway'
        }
    }
}

$StartingLocation = Get-Location

Push-Location \\path\to\ps\dsc\Config

$scriptblock1 = {
    if (!((Get-ChildItem Cert:\LocalMachine\My\BA54A10F29FA9DC057A3810FBF2B0853FC35789 -ErrorAction SilentlyContinue) -and (Get-ChildItem Cert:\LocalMachine\TrustedPublisher\BA54A10F29FA9DC057A3810FBF2B0853FC357899 -ErrorAction SilentlyContinue)))
    {
        Write-Output "Installing DSC Cert"
        $Key = Get-Content C:\Deployment\key.txt
        $Password = Invoke-RestMethod -Uri "https://enigma/api/passwords/8764?format=xml" -Method Get -ContentType "application/xml" -Headers @{"apikey"="$Key"}
        $SecurePassword = convertto-securestring -AsPlainText -Force -String $Password.ArrayOfPassword.Password.Password        
        $Creds = New-Object System.Management.Automation.PSCredential ("username", $SecurePassword)
        Import-PfxCertificate -Password $Creds.Password -FilePath C:\pki\DSCprivatekey.pfx -CertStoreLocation Cert:\LocalMachine\My
        Import-PfxCertificate -Password $Creds.Password -FilePath C:\pki\DSCprivatekey.pfx -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
    }
    elseif ((Get-ChildItem Cert:\LocalMachine\My\BA54A10F29FA9DC057A3810FBF2B0853FC357899 -ErrorAction SilentlyContinue) -and (Get-ChildItem Cert:\LocalMachine\TrustedPublisher\BA54A10F29FA9DC057A3810FBF2B0853FC357899 -ErrorAction SilentlyContinue))
    {
        Write-Output "DSC Cert is Installed"
    }
}

#Invoke-Command -ScriptBlock {Get-NetAdapter -Name 'Embedded LOM 1 Port*' | Set-DnsClient -RegisterThisConnectionsAddress $false} -ComputerName $NodeName
#Invoke-Command -ScriptBlock {Get-NetAdapter -Name 'Embedded LOM 1 Port*' | Get-DnsClient | fl} -ComputerName $NodeName

if (!($NoInitialConfig))
{
    InitialConfiguration -ConfigurationData '\\path\to\dsc\Exchange2016Setup\Configs\ExchangeConfiguration.psd1' -NodeName $NodeName
    ###Sets up LCM on target computers to decrypt credentials, and to allow reboot during resource execution
    Set-DscLocalConfigurationManager -Path .\InitialConfiguration -ComputerName $NodeName
    ###Pushes configuration and waits for execution
    Start-DscConfiguration -Path .\InitialConfiguration -ComputerName $NodeName -Force
}



if (!($NoNetwork))
{
    Invoke-Command -ScriptBlock $scriptblock1 -ComputerName $NodeName
    SetupNicTeam -ConfigurationData '\\path\to\dsc\Exchange2016Setup\Configs\ExchangeConfiguration.psd1' -NodeName $NodeName
    ###Pushes configuration and waits for execution
    Start-DscConfiguration -Path .\SetupNicTeam -ComputerName $NodeName -Verbose -Force
}

Push-Location $StartingLocation