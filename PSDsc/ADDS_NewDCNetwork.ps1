param (
    [string]$NodeName
)

Configuration ADDSConfigureNetwork
{
    Import-DscResource -ModuleName xNetworking -ModuleVersion 5.4.0.0
    Node $AllNodes.NodeName
    {
        xDhcpClient DisabledDhcpClient
        {
            State          = 'Disabled'
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = 'IPv4'
        }

        xIPAddress NewIPv4Address
        {
            IPAddress      = $Node.IPAddress
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = 'IPV4'

        }
        xDefaultGatewayAddress SetGateway
        {
            Address        = $Node.Gateway
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = 'IPv4'
        }
        xDnsServerAddress DnsServerAddress
        {
            Address        = $Node.DNSServer1
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = 'IPv4'
            Validate       = $false
        }
        xDnsConnectionSuffix DnsConnectionSuffix
        {
            InterfaceAlias           = $Node.InterfaceAlias
            ConnectionSpecificSuffix = 'spacex.corp'
        }
    }
}

$StartingLocation = Get-Location
Push-Location \\path\to\dsc\runpath
ADDSConfigureNetwork -ConfigurationData ("\\path\to\DSC\ADDCConfigs\$($NodeName).psd1")
Start-DscConfiguration -Path .\ADDSConfigureNetwork -ComputerName $NodeName -Force
Push-Location $StartingLocation 