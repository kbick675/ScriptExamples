param (
    [string]$NodeName
)
Configuration OpenDNS
{
    param (
        [string]$NodeName
    )
    Import-DscResource -ModuleName xDnsServer -ModuleVersion 1.9.0.0
    Node $NodeName
    {
        xDnsServerForwarder OpenDns
        {
            IsSingleInstance = 'Yes'
            IPAddresses = '208.67.222.222','208.67.220.220'
        }
    }
}

$StartingLocation = Get-Location
Push-Location \\path\to\dsc\runpath
OpenDNS -NodeName $NodeName
Start-DscConfiguration -Path .\OpenDNS -ComputerName $NodeName -Verbose -Wait
Push-Location $StartingLocation 