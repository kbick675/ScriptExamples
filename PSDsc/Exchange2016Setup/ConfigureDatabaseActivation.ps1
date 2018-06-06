Configuration ConfigureDatabasesActivation
{
    param
    (
        [PSCredential]$ShellCreds
    )

    Import-DscResource -ModuleName xExchange -ModuleVersion 1.19.0.0

    Node $AllNodes.NodeName
    {
        foreach ($DB in $Node.PrimaryDBList.Values)
        {
            $resourceId = "MDB$($DB.Name)" #Need to define a unique ID for each database

            xExchMailboxDatabaseCopy $resourceId
            {
                Identity             = $DB.Name
                Credential           = $ShellCreds
                MailboxServer        = $Node.NodeName
                ActivationPreference = '1'
                AllowServiceRestart  = $true
            }
        }
        foreach ($DB in $Node.CopyDBList.Values)
        {
            $resourceId = "MDB$($DB.Name)"

            xExchMailboxDatabaseCopy $resourceId
            {
                Identity             = $DB.Name
                Credential           = $ShellCreds
                MailboxServer        = $Node.NodeName
                ActivationPreference = $DB.ActivationPreference
                AllowServiceRestart  = $true
            }
        }
    }
}

if ($null -eq $ShellCreds)
{
    $ShellCreds = Get-Credential -Message 'Enter credentials for establishing Remote Powershell sessions to Exchange'
}

$StartingLocation = Get-Location

Push-Location \\filer1\ist\ps\dsc\Config

###Compiles the example
ConfigureDatabasesActivation -ConfigurationData '\\path\to\dsc\Exchange2016Setup\Configs\ExchangeConfiguration.psd1' -ShellCreds $ShellCreds

###Sets up LCM on target computers to decrypt credentials.
#Set-DscLocalConfigurationManager -Path .\ConfigureDatabasesManual -Verbose

###Pushes configuration and waits for execution
#Start-DscConfiguration -Path .\ConfigureDatabasesManual -Verbose -Wait 

Push-Location $StartingLocation
