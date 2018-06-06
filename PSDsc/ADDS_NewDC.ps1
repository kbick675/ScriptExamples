param (
    [string]$NodeName
)

Configuration ADDSNewDC
{
    param
    (
        [Parameter(Mandatory)]
        [pscredential]$safemodeAdministratorCred,
        [Parameter(Mandatory)]
        [pscredential]$domainCred
    )
    Import-DscResource -ModuleName xActiveDirectory -ModuleVersion 2.16.0.0
    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion 2.8.0.0
    Import-DscResource -ModuleName 'xDnsServer' -ModuleVersion 1.9.0.0
    Import-DscResource -ModuleName xNetworking -ModuleVersion 5.4.0.0

    Node $AllNodes.NodeName
    {
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
        }
        xWaitForADDomain DscForestWait
        {
            DomainName = $Node.DomainName
            DomainUserCredential = $domainCred
            RetryCount = $Node.RetryCount
            RetryIntervalSec = $Node.RetryIntervalSec
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
        xADDomainController NewDC
        {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $domainCred
            SafemodeAdministratorPassword = $safemodeAdministratorCred
            #DnsDelegationCredential = $DNSDelegationCred
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }
        MsiPackage nfrontFilter
        {
            Ensure = 'Present'
            Path = "\\path\to\packages\Installers\nFront\nfront-password-filter\nFront Password Filter 6.3.0 - x64 .msi"
            ProductId = '16971BB7-D07E-44AF-AE4A-7EF3301EB6BF'
            Arguments = '/qn /norestart'
            DependsOn = "[xADDomainController]NewDC"
        }
        if ($Node.NodeType -eq 'Access')
        {
            xDnsServerForwarder OpenDns
            {
                IsSingleInstance = 'Yes'
                IPAddresses = '208.67.222.222','208.67.220.220'
                DependsOn = "[xADDomainController]NewDC"
            }
            xDnsServerSecondaryZone xspacexcorp
            {
                Ensure = 'Present'
                Name = 'x.spacex.corp'
                MasterServers = '10.34.1.160'
            }
            xDnsServerSecondaryZone devxspacexcorp
            {
                Ensure = 'Present'
                Name = 'dev.x.spacex.corp'
                MasterServers = '10.34.1.160'
            }
        }
        if ($Node.NodeType -eq 'Mission')
        {
            Registry ntpservers
            {
                Ensure = 'Present'
                Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters'
                ValueName = "NtpServer"
                ValueData = $Node.NTPServers
                ValueType = "String"
                Force = $true
            }
            Registry ntpClientType
            {
                Ensure = "Present"
                Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
                ValueName = "Type"
                ValueData = "NTP"
                ValueType = "String"
                Force = $true
            }
            Registry ntpSpecialPollInterval
            {
                Ensure = "Present"
                Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient"
                ValueName = "SpecialPollInterval"
                ValueData = "60"
                ValueType = "Dword"
                Force = $true
            }
            Registry ntpEventLogFlags
            {
                Ensure = "Present"
                Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Config"
                ValueName = "EventLogFlags"
                ValueData = "1"
                ValueType = "Dword"
                Force = $true
            }
        }
        if ($Node.DNSType -eq 'Master')
        {
            xDnsServerPrimaryZone eprocsspacexcorp
            {
                Ensure = 'Present'
                Name = 'eprocs.spacex.corp'
                ZoneFile = 'eprocs.spacex.corp.dns'
                DynamicUpdate = 'None'
            }
            xDnsServerPrimaryZone eprocsccspacexcorp
            {
                Ensure = 'Present'
                Name = 'eprocs-cc.spacex.corp'
                ZoneFile = 'eprocs-cc.spacex.corp.dns'
                DynamicUpdate = 'None'
            }
            xDnsServerPrimaryZone eprocsvaspacexcorp
            {
                Ensure = 'Present'
                Name = 'eprocs-va.spacex.corp'
                ZoneFile = 'eprocs-va.spacex.corp.dns'
                DynamicUpdate = 'None'
            }
            xDnsServerSecondaryZone xspacexcorp
            {
                Ensure = 'Present'
                Name = 'x.spacex.corp'
                MasterServers = '10.34.1.160'
            }
            xDnsRecord eprocs
            {
                Ensure = 'Present'
                Target = '10.32.44.233'
                Name = '.'
                Zone = 'eprocs.spacex.corp'
                Type = 'ARecord'
                DependsOn = '[xDnsServerPrimaryZone]eprocsspacexcorp'
            }
            xDnsRecord eprocscc
            {
                Ensure = 'Present'
                Target = '10.80.46.245'
                Name = '.'
                Zone = 'eprocs-cc.spacex.corp'
                Type = 'ARecord'
                DependsOn = '[xDnsServerPrimaryZone]eprocsccspacexcorp'
            }
            xDnsRecord eprocsva
            {
                Ensure = 'Present'
                Name = '.'
                Target = '10.30.46.245'
                Zone = 'eprocs-va.spacex.corp'
                Type = 'ARecord'
                DependsOn = '[xDnsServerPrimaryZone]eprocsvaspacexcorp'
            }
        }
        if ($Node.DNSType -eq 'Secondary')
        {
            xDnsServerSecondaryZone xspacexcorp
            {
                Ensure = 'Present'
                Name = 'x.spacex.corp'
                MasterServers = '10.34.1.160'
            }
            xDnsServerSecondaryZone eprocsspacexcorp
            {
                Ensure = 'Present'
                Name = 'eprocs.spacex.corp'
                MasterServers = $Node.DNSMaster
            }           
            xDnsServerSecondaryZone eprocsccspacexcorp
            {
                Ensure = 'Present'
                Name = 'eprocs-cc.spacex.corp'
                MasterServers = $Node.DNSMaster
            }
            xDnsServerSecondaryZone eprocsvaspacexcorp
            {
                Ensure = 'Present'
                Name = 'eprocs-va.spacex.corp'
                MasterServers = $Node.DNSMaster
            }
        }      
        xDNSServerAddress PostDCNetwork
        {
            Address        = $Node.DNSServer2,$Node.DNSServer1
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = 'IPv4'
            Validate       = $true
            DependsOn = "[xADDomainController]NewDC"
        }
    }
}

try
{
    Test-WSMan -ComputerName $NodeName -ErrorAction SilentlyContinue
}
catch 
{
    Write-Output "Cannot connect to WSMan on $($NodeName)."
    break
}

$scriptblock = {
    if (!((Get-ChildItem Cert:\LocalMachine\My\BA54A10F29FA9DC057A3810FBF2B0853FC357899) -and (Get-ChildItem Cert:\LocalMachine\TrustedPublisher\BA54A10F29FA9DC057A3810FBF2B0853FC357899)))
    {
        Write-Output "Installing DSC Cert"
        $Key = Get-Content C:\Deployment\key.txt
        $Password = Invoke-RestMethod -Uri "https://enigma/api/passwords/8764?format=xml" -Method Get -ContentType "application/xml" -Headers @{"apikey"="$Key"}
        $SecurePassword = convertto-securestring -AsPlainText -Force -String $Password.ArrayOfPassword.Password.Password        
        $Creds = New-Object System.Management.Automation.PSCredential ("username", $SecurePassword)
        Import-PfxCertificate -Password $Creds.Password -FilePath C:\pki\DSCprivatekey.pfx -CertStoreLocation Cert:\LocalMachine\My
        Import-PfxCertificate -Password $Creds.Password -FilePath C:\pki\DSCprivatekey.pfx -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
    }
    elseif ((Get-ChildItem Cert:\LocalMachine\My\BA54A10F29FA9DC057A3810FBF2B0853FC357899) -and (Get-ChildItem Cert:\LocalMachine\TrustedPublisher\BA54A10F29FA9DC057A3810FBF2B0853FC357899))
    {
        Write-Output "DSC Cert is Installed"
    }
}

if ($null -eq $LocalCreds)
{
    $LocalCreds = Get-Credential -UserName 'username' -Message "Domain Safe Mode Admin Credentials"
}
if ($null -eq $DomainAdminCreds)
{
    $DomainAdminCreds = Get-Credential -Message "Domain Admin Credentials"
}

$StartingLocation = Get-Location
Push-Location \\path\to\dsc\runpath
Start-Sleep -Seconds 15
$count = 0
do {
    try 
    {
        Clear-DnsClientCache
        $Online = Test-WSMan -ComputerName $NodeName -ErrorAction SilentlyContinue
    }
    catch
    {   
    }
    $count++
    Start-Sleep -Seconds 15
} while (!($Online) -and ($count -le 60))
Write-Output "$($NodeName) is online."
Invoke-Command -ScriptBlock $scriptblock -ComputerName $NodeName
ADDSNewDC -ConfigurationData ("\\path\to\DSC\ADDCConfigs\$($NodeName).psd1") -safemodeAdministratorCred $LocalCreds -domainCred $DomainAdminCreds
Start-DscConfiguration -Path .\ADDSNewDC -ComputerName $NodeName -Force

Push-Location $StartingLocation 