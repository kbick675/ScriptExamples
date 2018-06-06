Configuration ConfigureDatabasesManual
{
    param
    (
        [PSCredential]$ShellCreds
    )

    Import-DscResource -ModuleName xExchange -ModuleVersion 1.19.0.0

    Node $AllNodes.NodeName
    {
        #Thumbprint of the certificate used to decrypt credentials on the target node
        <#
        LocalConfigurationManager
        {
            CertificateId = $Node.Thumbprint
        }
        #>
        $dagSettings = $ConfigurationData[$Node.DAGId] #Look up and retrieve the DAG settings for this node
        $casSettings = $ConfigurationData[$Node.CASId] #Look up and retrieve the CAS settings for this node
        #Create primary databases
        foreach ($DB in $Node.PrimaryDBList.Values)
        {
            $resourceId = "MDB$($DB.Name)" #Need to define a unique ID for each database

            xExchMailboxDatabase $resourceId 
            {
                Name                     = $DB.Name
                Credential               = $ShellCreds
                EdbFilePath              = $DB.EdbFilePath
                LogFolderPath            = $DB.LogFolderPath
                Server                   = $Node.NodeName
                CircularLoggingEnabled   = $false
                DatabaseCopyCount        = 1
                IssueWarningQuota        = "18432MB"
                ProhibitSendQuota        = "19456MB"
                ProhibitSendReceiveQuota = "20480MB"
                RecoverableItemsQuota    = "20480MB"
                RecoverableItemsWarningQuota = "10240MB"
                AllowServiceRestart      = $true
                OfflineAddressBook       = $casSettings.OABsToDistribute
            }
        }
        #Create the copies
        foreach ($DB in $Node.CopyDBList.Values)
        {
            $waitResourceId = "WaitForDB$($DB.Name)" #Unique ID for the xExchWaitForMailboxDatabase resource
            $copyResourceId = "MDBCopy$($DB.Name)" #Unique ID for the xExchMailboxDatabaseCopy resource 

            #Need to wait for a primary copy to be created before we add a copy
            xExchWaitForMailboxDatabase $waitResourceId
            {
                Identity   = $DB.Name
                Credential = $ShellCreds                
            }

            xExchMailboxDatabaseCopy $copyResourceId
            {
                Identity             = $DB.Name
                Credential           = $ShellCreds
                MailboxServer        = $Node.NodeName
                ActivationPreference = $DB.ActivationPreference
                ReplayLagTime        = $DB.ReplayLagTime
                AllowServiceRestart  = $true
                DependsOn            = "[xExchWaitForMailboxDatabase]$($waitResourceId)"
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
ConfigureDatabasesManual -ConfigurationData '\\path\to\dsc\Exchange2016Setup\Configs\ExchangeConfiguration.psd1' -ShellCreds $ShellCreds

###Sets up LCM on target computers to decrypt credentials.
#Set-DscLocalConfigurationManager -Path .\ConfigureDatabasesManual -Verbose

###Pushes configuration and waits for execution
#Start-DscConfiguration -Path .\ConfigureDatabasesManual -Verbose -Wait 

Push-Location $StartingLocation
