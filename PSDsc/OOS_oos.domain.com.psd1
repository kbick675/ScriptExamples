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
            NodeName = "vm-oos3"
            NodeFQDN = "vm-oos3.domain.corp" 
            Role = "FirstOOSNode"
            ExternalURL = "https://oos.domain.com"
            InternalURL = "https://oos.domain.corp"
            AllowHTTP = $true
            AllowOutboundHttp = $false
            SSLOffloaded = $false
            CertificateName = 'oos.domain.com'
            EditingEnabled = $true
            ClipArtEnabled = $false
            DocumentInfoCacheSize = 5000
            CacheSizeInGB = 15
            AllowCEIP = $false
            OfficeAddinEnabled = $false
            AllowHttpSecureStoreConnections = $true
            OpenFromUncEnabled = $true
            OpenFromUrlEnabled = $true
            OpenFromUrlThrottlingEnabled = $true
        },
        @{
            NodeName = "vm-oos4"
            NodeFQDN = "vm-oos4.domain.corp" 
            Role = "OOSMember"
        },
        @{
            NodeName = "vm-oos5"
            NodeFQDN = "vm-oos5.domain.corp" 
            Role = "OOSMember"
        }
    );
}