param (
    [string]$NodeName
)

Configuration ADDSPrepDC
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Node $AllNodes.NodeName
    {
        File xNetworkingFiles
        {
            Ensure = "Present"
            SourcePath = "\\filer1\ist\PS\Modules\xNetworking\5.4.0.0"
            DestinationPath = "C:\Program Files\WindowsPowerShell\Modules\xNetworking\5.4.0.0"
            Recurse = $true
            Type = "Directory"
            MatchSource = $true
        }
        File xPSDesiredStateConfiguration
        {
            Ensure = "Present"
            SourcePath = "\\filer1\ist\PS\Modules\xPSDesiredStateConfiguration\8.0.0.0"
            DestinationPath = "C:\Program Files\WindowsPowerShell\Modules\xPSDesiredStateConfiguration\8.0.0.0"
            Recurse = $true
            Type = "Directory"
            MatchSource = $true
        }
        File xActiveDirectory
        {
            Ensure = "Present"
            SourcePath = "\\filer1\ist\PS\Modules\xActiveDirectory\2.16.0.0"
            DestinationPath = "C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory\2.16.0.0"
            Recurse = $true
            Type = "Directory"
            MatchSource = $true
        }
        File xDnsServer
        {
            Ensure = "Present"
            SourcePath = "\\filer1\ist\PS\Modules\xDnsServer\1.9.0.0"
            DestinationPath = "C:\Program Files\WindowsPowershell\Modules\xDnsServer\1.9.0.0"
            Type = "Directory"
            Recurse = $true
            MatchSource = $true
        }
        File PSDscResources
        {
            Ensure = "Present"
            SourcePath = "\\filer1\ist\PS\Modules\PSDscResources\2.8.0.0"
            DestinationPath = "C:\Program Files\WindowsPowershell\Modules\PSDscResources\2.8.0.0"
            Type = "Directory"
            Recurse = $true
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
        LocalConfigurationManager
        {
            CertificateID = $Node.Thumbprint
            RebootNodeIfNeeded = $true
        }
    }
}

$StartingLocation = Get-Location
Push-Location \\path\to\dsc\runpath
ADDSPrepDC -ConfigurationData ("\\path\to\DSC\ADDCConfigs\$($NodeName).psd1")
Set-DscLocalConfigurationManager -Path .\ADDSPrepDC -ComputerName $NodeName -Force
Start-DscConfiguration -Path .\ADDSPrepDC -ComputerName $NodeName -Force -Wait
Push-Location $StartingLocation