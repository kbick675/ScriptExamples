param (
    [string]$NodeName
)

Configuration InstallExchange
{
    param
    (
        [PSCredential]$Creds,
        [PSCredential]$CertCreds
    )

    Import-DscResource -ModuleName xExchange -ModuleVersion 1.19.0.0
    Import-DscResource -ModuleName xPendingReboot -ModuleVersion 0.3.0.0
    Import-DscResource -ModuleName xCertificate -ModuleVersion 3.2.0.0

    Node $AllNodes.NodeName
    {
        $dagSettings = $ConfigurationData[$Node.DAGId] #Look up and retrieve the DAG settings for this node
        $casSettings = $ConfigurationData[$Node.CASId] #Look up and retrieve the CAS settings for this node
        #Check if a reboot is needed before installing Exchange
        xPendingReboot BeforeExchangeInstall
        {
            Name      = "BeforeExchangeInstall"
        }
        xExchWaitForADPrep WaitForADPrep
        {
            Identity = "Doesn'tMatter"
            Credential = $Creds
            SchemaVersion = 15332
            OrganizationVersion = 16213
            DomainVersion = 13236
            DependsOn  = '[xPendingReboot]BeforeExchangeInstall'
        }
        #Do the Exchange install
        xExchInstall InstallExchange
        {
            Path       = "C:\SetupBinaries\E16CU8\Setup.exe"
            Arguments  = "/mode:Install /role:Mailbox /IAcceptExchangeServerLicenseTerms"
            Credential = $Creds
            DependsOn  = '[xExchWaitForADPrep]WaitForADPrep'
        }
        #See if a reboot is required after installing Exchange
        xPendingReboot AfterExchangeInstall
        {
            Name      = "AfterExchangeInstall"
            DependsOn = '[xExchInstall]InstallExchange'
        }
        xExchExchangeCertificate Certificate
        {
            Thumbprint         = $dagSettings.Thumbprint
            Credential         = $Creds
            Ensure             = 'Present'
            AllowExtraServices = $dagSettings.AllowExtraServices        
            CertCreds          = $CertCreds
            CertFilePath       = $dagSettings.CertFilePath
            Services           = $dagSettings.Services
            DependsOn          = '[xPendingReboot]AfterExchangeInstall'
        }
        xCertificateImport adfssigning
        {
            Thumbprint = $casSettings.ADFSSigningThumbprint
            Location   = 'LocalMachine'
            Store      = 'Root'
            Path       = $casSettings.ADFSSigningPath
        }
    }
}

if ($null -eq $Creds)
{
    $Creds = Get-Credential -Message "Enter credentials for establishing Remote Powershell sessions to Exchange"
}
if ($null -eq $CertCreds)
{
    $CertCreds = Get-Credential -UserName 'PfxPassword' -Message 'Enter credentials for importing the Exchange certificate'
}

$StartingLocation = Get-Location

Push-Location \\filer1\ist\ps\dsc\Config

###Compiles the example
InstallExchange -ConfigurationData '\\path\to\dsc\Exchange2016Setup\Configs\ExchangeConfiguration.psd1' -Creds $Creds -Certcreds $CertCreds
###Pushes configuration and waits for execution
#Start-DscConfiguration -Path .\InstallExchange -Verbose -ComputerName $NodeName

Push-Location $StartingLocation
