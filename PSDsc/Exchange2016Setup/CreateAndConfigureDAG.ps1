Configuration CreateAndConfigureDAG
{
    param
    (
        [PSCredential]$ShellCreds
    )

    Import-DscResource -ModuleName xExchange -ModuleVersion 1.19.0.0


    #This section only configures a single DAG node, the first member of the DAG.
    #The first member of the DAG will be responsible for DAG creation and maintaining its configuration
    Node $AllNodes.Where{$_.Role -eq 'FirstDAGMember'}.NodeName
    {
        $dagSettings = $ConfigurationData[$Node.DAGId] #Look up and retrieve the DAG settings for this node
        $casSettings = $ConfigurationData[$Node.CASId] #Look up and retrieve the CAS settings for this node

        WindowsFeature FailoverClustering
        {
            Ensure = 'Present'
            Name = "Failover-clustering"
        }
        #Create the DAG
        xExchDatabaseAvailabilityGroup DAG
        {
            Name                                 = $dagSettings.DAGName
            Credential                           = $ShellCreds
            AutoDagTotalNumberOfServers          = 0
            AutoDagDatabaseCopiesPerDatabase     = 1
            AutoDagDatabaseCopiesPerVolume       = 2
            AutoDagTotalNumberOfDatabases        = 0
            DatacenterActivationMode             = 'Off'
            DatabaseAvailabilityGroupIPAddresses = $dagSettings.DatabaseAvailabilityGroupIPAddresses 
            ManualDagNetworkConfiguration        = $true
            ReplayLagManagerEnabled              = $true
            SkipDagValidation                    = $false
            WitnessDirectory                     = $dagSettings.WitnessDirectory
            WitnessServer                        = $dagSettings.WitnessServer
            AlternateWitnessDirectory            = $dagSettings.AlternateWitnessDirectory
            AlternateWitnessServer               = $dagSettings.AlternateWitnessServer
            DependsOn                            = '[WindowsFeature]FailoverClustering'
        }

        #Add this server as member
        xExchDatabaseAvailabilityGroupMember DAGMember
        {
            MailboxServer     = $Node.NodeName
            Credential        = $ShellCreds
            DAGName           = $dagSettings.DAGName
            SkipDagValidation = $true
            DependsOn         = '[xExchDatabaseAvailabilityGroup]DAG'
        }

        #Create two new DAG Networks
        xExchDatabaseAvailabilityGroupNetwork DAGNet1
        {
            Name                      = $dagSettings.DAGNet1NetworkName
            Credential                = $ShellCreds
            DatabaseAvailabilityGroup = $dagSettings.DAGName
            Ensure                    = 'Present'
            ReplicationEnabled        = $dagSettings.DAGNet1ReplicationEnabled
            Subnets                   = $dagSettings.DAGNet1Subnets
            DependsOn                 = '[xExchDatabaseAvailabilityGroupMember]DAGMember' #Can't do work on DAG networks until at least one member is in the DAG...
        }
    }
    #Next we'll add the remaining nodes to the DAG
    Node $AllNodes.Where{$_.Role -eq 'AdditionalDAGMember'}.NodeName
    {
        $dagSettings = $ConfigurationData[$Node.DAGId] #Look up and retrieve the DAG settings for this node
        $casSettings = $ConfigurationData[$Node.CASId] #Look up and retrieve the CAS settings for this node

        WindowsFeature FailoverClustering
        {
            Ensure = 'Present'
            Name = "Failover-clustering"
        }
        #Can't join until the DAG exists...
        xExchWaitForDAG WaitForDAG
        {
            Identity   = $dagSettings.DAGName
            Credential = $ShellCreds
        }
        xExchDatabaseAvailabilityGroupMember DAGMember
        {
            MailboxServer     = $Node.NodeName
            Credential        = $ShellCreds
            DAGName           = $dagSettings.DAGName
            SkipDagValidation = $true
            DependsOn         = '[xExchWaitForDAG]WaitForDAG','[WindowsFeature]FailoverClustering'
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
CreateAndConfigureDAG -ConfigurationData '\\path\to\dsc\Exchange2016Setup\Configs\ExchangeConfiguration.psd1' -ShellCreds $ShellCreds

###Sets up LCM on target computers to decrypt credentials.
#Set-DscLocalConfigurationManager -Path .\CreateAndConfigureDAG -Verbose

###Pushes configuration and waits for execution
#Start-DscConfiguration -Path .\CreateAndConfigureDAG -Verbose -Wait 

Push-Location $StartingLocation