@{
    AllNodes = @(
        #Settings in this section will apply to all nodes. For the purposes of this demo,
        #the only thing that will be configured in here is how credentials will be stored
        #in the compiled MOF files.
        @{
            NodeName = "*"

            ###SECURE CREDENTIAL PASSING METHOD###
            #This is the preferred method for passing credentials, as they are not stored in plain text. See:
            #http://blogs.msdn.com/b/powershell/archive/2014/01/31/want-to-secure-credentials-in-windows-powershell-desired-state-configuration.aspx
            
            # The path to the .cer file containing the 
            # public key of the Encryption Certificate 
            # used to encrypt credentials for this node 
            CertificateFile = "C:\pki\DSCpub.cer" 

            #Thumbprint of the certificate being used for encrypting credentials
            Thumbprint      = 'BA54A10F29FA9DC057A3810FBF2B0853FC357899'
        }

        @{
            NodeName = "ht-vm-dc-m4"
            NodeType = "Mission"
            DNSType = "Secondary"
            DNSMaster = "ht-mc-dc-m1.domain.corp"
            DomainName = "domain.corp"
            PSDscAllowDomainUser = $true
            RetryCount = 20
            RetryIntervalSec = 30
            IPAddress = '10.32.44.11/22'
            DNSServer1 = '10.32.44.10'
            DNSServer2 = '127.0.0.1'
            GateWay = '10.32.44.1'
            InterfaceAlias = 'Ethernet'
            NTPServers = "gpsclock1.domain.corp,0x01 gpsclock2.domain.corp,0x01 ntp.domain.corp,0x01"
        }
    );
}