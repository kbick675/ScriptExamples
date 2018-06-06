param (
    [string]$NodeName
)
Configuration Webconfigtest
{
    Import-DscResource -ModuleName xWebAdministration -ModuleVersion 1.19.0.0
    Node $AllNodes.NodeName
    {
        $casSettings = $ConfigurationData[$Node.CASId]
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
    }
}


$StartingLocation = Get-Location

Push-Location \\filer1\ist\ps\dsc\Config
###Compiles the example
Webconfigtest -ConfigurationData '\\path\to\dsc\Exchange2016Setup\Configs\ExchangeConfiguration.psd1'

###Pushes configuration and waits for execution
Start-DscConfiguration -Path .\Webconfigtest -Verbose -Wait -ComputerName $NodeName
Push-Location $StartingLocation