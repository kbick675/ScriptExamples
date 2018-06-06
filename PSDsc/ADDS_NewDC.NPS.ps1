param (
    [string]$NodeName
)

Configuration PrepDC
{
    Import-DscResource -ModuleName 'PSDSCResources' -ModuleVersion 2.8.0.0
    Node $AllNodes.NodeName
    {
        File xActiveDirectory
        {
            Ensure = "Present"
            SourcePath = "\\filer1\ist\PS\Modules\xActiveDirectory\2.16.0.0"
            DestinationPath = "C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory\2.16.0.0"
            Recurse = $true
            Type = "Directory"
            MatchSource = $true
        }
        File PublicKey
        {
            Ensure = "Present"
            SourcePath = "\\filer1\IST\PS\DSC\certificates\DSCpub.cer"
            DestinationPath = "C:\PKI\DSCpub.cer"
            Type = "File"
            MatchSource = $true
        }
        File PrivateKey
        {
            Ensure = "Present"
            SourcePath = "\\filer1\IST\PS\DSC\certificates\DSCprivatekey.pfx"
            DestinationPath = "C:\PKI\DSCprivatekey.pfx"
            Type = "File"
            MatchSource = $true
        }
        File dsccertenigmakey
        {
            Ensure = "Present"
            SourcePath = "\\filer1\IST\PS\DSC\Certificates\key.txt"
            DestinationPath = "C:\Deployment\key.txt"
            Type = "File"
            MatchSource = $true
        }
        File NPSFolder
        {
            Ensure = "Present"
            DestinationPath = "C:\nps"
            Type = "Directory"
        }
        File NPSLogFolder
        {
            Ensure = "Present"
            DestinationPath = "c:\Windows\System32\LogFiles\NPS"
            Type = "Directory"
        }
        LocalConfigurationManager
        {
            CertificateID = $Node.Thumbprint
            RebootNodeIfNeeded = $true
        }
    }
}

Configuration NewDC
{
    param
    (
        [Parameter(Mandatory)]
        [pscredential]$safemodeAdministratorCred,
        [Parameter(Mandatory)]
        [pscredential]$domainCred
    )
    Import-DscResource -ModuleName xActiveDirectory -ModuleVersion 2.16.0.0
    Import-DscResource -ModuleName 'PSDSCResources' -ModuleVersion 2.8.0.0

    Node $AllNodes.NodeName
    {
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
        }
        WindowsFeature NPS
        {
            Ensure = "Present"
            Name = "NPAS"
            IncludeAllSubFeature = $true
        }
        WindowsFeature RSAT_NPS
        {
            Ensure = "Present"
            Name = "RSAT-NPAS"
            IncludeAllSubFeature = $true
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
    }
}


$Config = @{
    AllNodes = @(
        @{
            NodeName = "$($NodeName)"
            DomainName = "spacex.corp"
            CertificateFile = "C:\pki\DSCpub.cer"
            Thumbprint = 'BA54A10F29FA9DC057A3810FBF2B0853FC357899'
            PSDscAllowDomainUser = $true
            RetryCount = 20
            RetryIntervalSec = 30
            InterfaceAlias = 'Ethernet0'
        }
    )
}
$Connection = Test-WSMan -ComputerName $NodeName
if (!($Connection))
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
        Import-PfxCertificate -Password $Creds.Password -FilePath C:\pki\DSCDSCprivatekey.pfx -CertStoreLocation Cert:\LocalMachine\My
        Import-PfxCertificate -Password $Creds.Password -FilePath C:\pki\DSCDSCprivatekey.pfx -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
    }
    elseif (!((Get-ChildItem Cert:\LocalMachine\My\BA54A10F29FA9DC057A3810FBF2B0853FC357899) -and (Get-ChildItem Cert:\LocalMachine\TrustedPublisher\BA54A10F29FA9DC057A3810FBF2B0853FC357899)))
    {
        Write-Output "DSC Cert is Installed"
    }
}

$StartingLocation = Get-Location
Push-Location \\path\to\dsc\runpath
PrepDC -ConfigurationData $Config
Set-DscLocalConfigurationManager -Path .\PrepDC -ComputerName $NodeName -Force
Start-DscConfiguration -Path .\PrepDC -ComputerName $NodeName -Force -Wait
Invoke-Command -ScriptBlock $scriptblock -ComputerName $NodeName
$count = 0
do {
    Start-Sleep -Seconds 15
    try 
    {
        Clear-DnsClientCache
        $Online = Test-WSMan -ComputerName $NodeName
    }
    catch
    {   
    }
    $count++
} while (!($Online) -and ($count -le 30))

NewDC -ConfigurationData $Config -safemodeAdministratorCred (Get-Credential -UserName 'username' -Message "New Domain Safe Mode Admin Credentials") -domainCred (Get-Credential -Message "New Domain Admin Credentials")
Start-DscConfiguration -Path .\NewDC -ComputerName $NodeName -Force
Push-Location $StartingLocation 