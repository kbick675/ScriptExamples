@{
    AllNodes = @(
        #Settings under "NodeName = *" apply to all nodes.
        @{
            NodeName        = "*"

            #CertificateFile and Thumbprint are used for securing credentials. See:
            #http://blogs.msdn.com/b/powershell/archive/2014/01/31/want-to-secure-credentials-in-windows-powershell-desired-state-configuration.aspx
            
            #The location on the compiling machine of the public key export of the certfificate which will be used to encrypt credentials
            CertificateFile = "C:\pki\DSCpub.cer" 

            #Thumbprint of the certificate being used for encrypting credentials
            Thumbprint      = "BA54A10F29FA9DC057A3810FBF2B0853FC357899"
        }

        #Individual target nodes are defined next
        #dc-ex-d1-n1
        @{
            NodeName    = "dc-ex-d1-n1"
            Fqdn        = "dc-ex-d1-n1.domain.corp"
            IPAddress2000   = "10.34.3.230/22"
            Role        = "FirstDAGMember"
            PSDscAllowDomainUser = $true
            DAGId       = "EXD1" #Used to determine which DAG settings the servers should use. Corresponds to DAG1 hashtable entry below.
            CASId       = "CAS1" #Used to determine which CAS settings the server should use. Corresponds to CAS1 hashtable entry below.
            #Configure the databases whose primary copies will reside on this server
            PrimaryDBList = @{
                DB1 = @{Name = "EXD1DB1"; EdbFilePath = "C:\mountpath\EXD1DBVol1\EXD1DB1\EXD1DB1.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol1\EXD1DB1\Log"};
                DB4 = @{Name = "EXD1DB4"; EdbFilePath = "C:\mountpath\EXD1DBVol2\EXD1DB4\EXD1DB4.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol2\EXD1DB4\Log"};
                DB7 = @{Name = "EXD1DB7"; EdbFilePath = "C:\mountpath\EXD1DBVol4\EXD1DB7\EXD1DB7.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol4\EXD1DB7\Log"};
                DB10 = @{Name = "EXD1DB10"; EdbFilePath = "C:\mountpath\EXD1DBVol5\EXD1DB10\EXD1DB10.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol5\EXD1DB10\Log"};
                DB13 = @{Name = "EXD1DB13"; EdbFilePath = "C:\mountpath\EXD1DBVol7\EXD1DB13\EXD1DB13.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol7\EXD1DB13\Log"};
                DB16 = @{Name = "EXD1DB16"; EdbFilePath = "C:\mountpath\EXD1DBVol8\EXD1DB16\EXD1DB16.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol8\EXD1DB16\Log"};
                DB19 = @{Name = "EXD1DB19"; EdbFilePath = "C:\mountpath\EXD1DBVol10\EXD1DB19\EXD1DB19.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol10\EXD1DB19\Log"};
                DB22 = @{Name = "EXD1DB22"; EdbFilePath = "C:\mountpath\EXD1DBVol11\EXD1DB22\EXD1DB22.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol11\EXD1DB22\Log"};
                DB25 = @{Name = "EXD1DB25"; EdbFilePath = "C:\mountpath\EXD1DBVol13\EXD1DB25\EXD1DB25.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol13\EXD1DB25\Log"};
                DB28 = @{Name = "EXD1DB28"; EdbFilePath = "C:\mountpath\EXD1DBVol14\EXD1DB28\EXD1DB28.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol14\EXD1DB28\Log"};
                DB31 = @{Name = "EXD1DB31"; EdbFilePath = "C:\mountpath\EXD1DBVol16\EXD1DB31\EXD1DB31.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol16\EXD1DB31\Log"};
                DB34 = @{Name = "EXD1DB34"; EdbFilePath = "C:\mountpath\EXD1DBVol17\EXD1DB34\EXD1DB34.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol17\EXD1DB34\Log"};
                DB37 = @{Name = "EXD1DB37"; EdbFilePath = "C:\mountpath\EXD1DBVol19\EXD1DB37\EXD1DB37.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol19\EXD1DB37\Log"};
                DB40 = @{Name = "EXD1DB40"; EdbFilePath = "C:\mountpath\EXD1DBVol20\EXD1DB40\EXD1DB40.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol20\EXD1DB40\Log"};
                DB43 = @{Name = "EXD1DB43"; EdbFilePath = "C:\mountpath\EXD1DBVol22\EXD1DB43\EXD1DB43.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol22\EXD1DB43\Log"};
                DB46 = @{Name = "EXD1DB46"; EdbFilePath = "C:\mountpath\EXD1DBVol23\EXD1DB46\EXD1DB46.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol23\EXD1DB46\Log"}
            }

            #Configure the copies next.
            CopyDBList    = @{
                DB2 = @{Name = "EXD1DB2"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB3 = @{Name = "EXD1DB3"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB5 = @{Name = "EXD1DB5"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB6 = @{Name = "EXD1DB6"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB8 = @{Name = "EXD1DB8"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB9 = @{Name = "EXD1DB9"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB11 = @{Name = "EXD1DB11"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB12 = @{Name = "EXD1DB12"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB14 = @{Name = "EXD1DB14"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB15 = @{Name = "EXD1DB15"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB17 = @{Name = "EXD1DB17"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB18 = @{Name = "EXD1DB18"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB20 = @{Name = "EXD1DB20"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB21 = @{Name = "EXD1DB21"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB23 = @{Name = "EXD1DB23"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB24 = @{Name = "EXD1DB24"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB26 = @{Name = "EXD1DB26"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB27 = @{Name = "EXD1DB27"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB29 = @{Name = "EXD1DB29"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB30 = @{Name = "EXD1DB30"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB32 = @{Name = "EXD1DB32"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB33 = @{Name = "EXD1DB33"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB35 = @{Name = "EXD1DB35"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB36 = @{Name = "EXD1DB36"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB38 = @{Name = "EXD1DB38"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB39 = @{Name = "EXD1DB39"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB41 = @{Name = "EXD1DB41"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB42 = @{Name = "EXD1DB42"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB44 = @{Name = "EXD1DB44"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB45 = @{Name = "EXD1DB45"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB47 = @{Name = "EXD1DB47"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB48 = @{Name = "EXD1DB48"; ActivationPreference = 3; ReplayLagTime = "00:00:00"}
            }
        }
        #dc-ex-d1-n2
        @{
            NodeName    = "dc-ex-d1-n2"
            Fqdn        = "dc-ex-d1-n2.domain.corp"
            IPAddress2000   = "10.34.3.231/22"
            Role        = "AdditionalDAGMember"
            PSDscAllowDomainUser = $true
            DAGId       = "EXD1"
            CASID       = "CAS1"
            #Configure the databases whose primary copies will reside on this server
            PrimaryDBList = @{
                DB2 = @{Name = "EXD1DB2"; EdbFilePath = "C:\mountpath\EXD1DBVol1\EXD1DB2\EXD1DB2.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol1\EXD1DB2\Log"};
                DB5 = @{Name = "EXD1DB5"; EdbFilePath = "C:\mountpath\EXD1DBVol3\EXD1DB5\EXD1DB5.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol3\EXD1DB5\Log"};
                DB8 = @{Name = "EXD1DB8"; EdbFilePath = "C:\mountpath\EXD1DBVol4\EXD1DB8\EXD1DB8.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol4\EXD1DB8\Log"};
                DB11 = @{Name = "EXD1DB11"; EdbFilePath = "C:\mountpath\EXD1DBVol6\EXD1DB11\EXD1DB11.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol6\EXD1DB11\Log"};
                DB14 = @{Name = "EXD1DB14"; EdbFilePath = "C:\mountpath\EXD1DBVol7\EXD1DB14\EXD1DB14.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol7\EXD1DB14\Log"};
                DB17 = @{Name = "EXD1DB17"; EdbFilePath = "C:\mountpath\EXD1DBVol9\EXD1DB17\EXD1DB17.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol9\EXD1DB17\Log"};
                DB20 = @{Name = "EXD1DB20"; EdbFilePath = "C:\mountpath\EXD1DBVol10\EXD1DB20\EXD1DB20.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol10\EXD1DB20\Log"};
                DB23 = @{Name = "EXD1DB23"; EdbFilePath = "C:\mountpath\EXD1DBVol12\EXD1DB23\EXD1DB23.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol12\EXD1DB23\Log"};
                DB26 = @{Name = "EXD1DB26"; EdbFilePath = "C:\mountpath\EXD1DBVol13\EXD1DB26\EXD1DB26.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol13\EXD1DB26\Log"};
                DB29 = @{Name = "EXD1DB29"; EdbFilePath = "C:\mountpath\EXD1DBVol15\EXD1DB29\EXD1DB29.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol15\EXD1DB29\Log"};
                DB32 = @{Name = "EXD1DB32"; EdbFilePath = "C:\mountpath\EXD1DBVol16\EXD1DB32\EXD1DB32.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol16\EXD1DB32\Log"};
                DB35 = @{Name = "EXD1DB35"; EdbFilePath = "C:\mountpath\EXD1DBVol18\EXD1DB35\EXD1DB35.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol18\EXD1DB35\Log"};
                DB38 = @{Name = "EXD1DB38"; EdbFilePath = "C:\mountpath\EXD1DBVol19\EXD1DB38\EXD1DB38.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol19\EXD1DB38\Log"};
                DB41 = @{Name = "EXD1DB41"; EdbFilePath = "C:\mountpath\EXD1DBVol21\EXD1DB41\EXD1DB41.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol21\EXD1DB41\Log"};
                DB44 = @{Name = "EXD1DB44"; EdbFilePath = "C:\mountpath\EXD1DBVol22\EXD1DB44\EXD1DB44.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol22\EXD1DB44\Log"};
                DB47 = @{Name = "EXD1DB47"; EdbFilePath = "C:\mountpath\EXD1DBVol24\EXD1DB47\EXD1DB47.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol24\EXD1DB47\Log"}
            }

            #Configure the copies next.
            CopyDBList    = @{
                DB1 = @{Name = "EXD1DB1"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB3 = @{Name = "EXD1DB3"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB4 = @{Name = "EXD1DB4"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB6 = @{Name = "EXD1DB6"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB7 = @{Name = "EXD1DB7"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB9 = @{Name = "EXD1DB9"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB10 = @{Name = "EXD1DB10"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB12 = @{Name = "EXD1DB12"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB13 = @{Name = "EXD1DB13"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB15 = @{Name = "EXD1DB15"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB16 = @{Name = "EXD1DB16"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB18 = @{Name = "EXD1DB18"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB19 = @{Name = "EXD1DB19"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB21 = @{Name = "EXD1DB21"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB22 = @{Name = "EXD1DB22"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB24 = @{Name = "EXD1DB24"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB25 = @{Name = "EXD1DB25"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB27 = @{Name = "EXD1DB27"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB28 = @{Name = "EXD1DB28"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB30 = @{Name = "EXD1DB30"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB31 = @{Name = "EXD1DB31"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB33 = @{Name = "EXD1DB33"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB34 = @{Name = "EXD1DB34"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB36 = @{Name = "EXD1DB36"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB37 = @{Name = "EXD1DB37"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB39 = @{Name = "EXD1DB39"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB40 = @{Name = "EXD1DB40"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB42 = @{Name = "EXD1DB42"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB43 = @{Name = "EXD1DB43"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB45 = @{Name = "EXD1DB45"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB46 = @{Name = "EXD1DB46"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB48 = @{Name = "EXD1DB48"; ActivationPreference = 2; ReplayLagTime = "00:00:00"}
            }
        }
        #dc-ex-d1-n3
        @{
            NodeName    = "dc-ex-d1-n3"
            Fqdn        = "dc-ex-d1-n3.domain.corp"
            IPAddress2000   = "10.34.3.232/22"
            Role        = "AdditionalDAGMember"
            PSDscAllowDomainUser = $true
            DAGId       = "EXD1"
            CASID       = "CAS1"
            #Configure the databases whose primary copies will reside on this server
            PrimaryDBList = @{
                DB3 = @{Name = "EXD1DB3"; EdbFilePath = "C:\mountpath\EXD1DBVol2\EXD1DB3\EXD1DB3.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol2\EXD1DB3\Log"};
                DB6 = @{Name = "EXD1DB6"; EdbFilePath = "C:\mountpath\EXD1DBVol3\EXD1DB6\EXD1DB6.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol3\EXD1DB6\Log"};
                DB9 = @{Name = "EXD1DB9"; EdbFilePath = "C:\mountpath\EXD1DBVol5\EXD1DB9\EXD1DB9.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol5\EXD1DB9\Log"};
                DB12 = @{Name = "EXD1DB12"; EdbFilePath = "C:\mountpath\EXD1DBVol6\EXD1DB12\EXD1DB12.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol6\EXD1DB12\Log"};
                DB15 = @{Name = "EXD1DB15"; EdbFilePath = "C:\mountpath\EXD1DBVol8\EXD1DB15\EXD1DB15.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol8\EXD1DB15\Log"};
                DB18 = @{Name = "EXD1DB18"; EdbFilePath = "C:\mountpath\EXD1DBVol9\EXD1DB18\EXD1DB18.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol9\EXD1DB18\Log"};
                DB21 = @{Name = "EXD1DB21"; EdbFilePath = "C:\mountpath\EXD1DBVol11\EXD1DB21\EXD1DB21.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol11\EXD1DB21\Log"};
                DB24 = @{Name = "EXD1DB24"; EdbFilePath = "C:\mountpath\EXD1DBVol12\EXD1DB24\EXD1DB24.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol12\EXD1DB24\Log"};
                DB27 = @{Name = "EXD1DB27"; EdbFilePath = "C:\mountpath\EXD1DBVol14\EXD1DB27\EXD1DB27.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol14\EXD1DB27\Log"};
                DB30 = @{Name = "EXD1DB30"; EdbFilePath = "C:\mountpath\EXD1DBVol15\EXD1DB30\EXD1DB30.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol15\EXD1DB30\Log"};
                DB33 = @{Name = "EXD1DB33"; EdbFilePath = "C:\mountpath\EXD1DBVol17\EXD1DB33\EXD1DB33.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol17\EXD1DB33\Log"};
                DB36 = @{Name = "EXD1DB36"; EdbFilePath = "C:\mountpath\EXD1DBVol18\EXD1DB36\EXD1DB36.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol18\EXD1DB36\Log"};
                DB39 = @{Name = "EXD1DB39"; EdbFilePath = "C:\mountpath\EXD1DBVol20\EXD1DB39\EXD1DB39.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol20\EXD1DB39\Log"};
                DB42 = @{Name = "EXD1DB42"; EdbFilePath = "C:\mountpath\EXD1DBVol21\EXD1DB42\EXD1DB42.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol21\EXD1DB42\Log"};
                DB45 = @{Name = "EXD1DB45"; EdbFilePath = "C:\mountpath\EXD1DBVol23\EXD1DB45\EXD1DB45.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol23\EXD1DB45\Log"};
                DB48 = @{Name = "EXD1DB48"; EdbFilePath = "C:\mountpath\EXD1DBVol24\EXD1DB48\EXD1DB48.edb"; LogFolderPath = "C:\mountpath\EXD1DBVol24\EXD1DB48\Log"}
            }

            #Configure the copies next.
            CopyDBList    = @{
                DB1 = @{Name = "EXD1DB1"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB2 = @{Name = "EXD1DB2"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB4 = @{Name = "EXD1DB4"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB5 = @{Name = "EXD1DB5"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB7 = @{Name = "EXD1DB7"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB8 = @{Name = "EXD1DB8"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB10 = @{Name = "EXD1DB10"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB11 = @{Name = "EXD1DB11"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB13 = @{Name = "EXD1DB13"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB14 = @{Name = "EXD1DB14"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB16 = @{Name = "EXD1DB16"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB17 = @{Name = "EXD1DB17"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB19 = @{Name = "EXD1DB19"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB20 = @{Name = "EXD1DB20"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB22 = @{Name = "EXD1DB22"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB23 = @{Name = "EXD1DB23"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB25 = @{Name = "EXD1DB25"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB26 = @{Name = "EXD1DB26"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB28 = @{Name = "EXD1DB28"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB29 = @{Name = "EXD1DB29"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB31 = @{Name = "EXD1DB31"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB32 = @{Name = "EXD1DB32"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB34 = @{Name = "EXD1DB34"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB35 = @{Name = "EXD1DB35"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB37 = @{Name = "EXD1DB37"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB38 = @{Name = "EXD1DB38"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB40 = @{Name = "EXD1DB40"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB41 = @{Name = "EXD1DB41"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB43 = @{Name = "EXD1DB43"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB44 = @{Name = "EXD1DB44"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB46 = @{Name = "EXD1DB46"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB47 = @{Name = "EXD1DB47"; ActivationPreference = 3; ReplayLagTime = "00:00:00"}

            }
        }
        #dc-ex-d2-n1
        @{
            NodeName    = "dc-ex-d2-n1"
            Fqdn        = "dc-ex-d2-n1.domain.corp"
            IPAddress2000   = "10.34.3.233/22"
            Role        = "FirstDAGMember"
            PSDscAllowDomainUser = $true
            DAGId       = "EXD2" #Used to determine which DAG settings the servers should use. Corresponds to DAG1 hashtable entry below.
            CASId       = "CAS1" #Used to determine which CAS settings the server should use. Corresponds to CAS1 hashtable entry below.
            #Configure the databases whose primary copies will reside on this server
            PrimaryDBList = @{
                DB1 = @{Name = "EXD2DB1"; EdbFilePath = "C:\mountpath\EXD2DBVol1\EXD2DB1\EXD2DB1.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol1\EXD2DB1\Log"};
                DB4 = @{Name = "EXD2DB4"; EdbFilePath = "C:\mountpath\EXD2DBVol2\EXD2DB4\EXD2DB4.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol2\EXD2DB4\Log"};
                DB7 = @{Name = "EXD2DB7"; EdbFilePath = "C:\mountpath\EXD2DBVol4\EXD2DB7\EXD2DB7.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol4\EXD2DB7\Log"};
                DB10 = @{Name = "EXD2DB10"; EdbFilePath = "C:\mountpath\EXD2DBVol5\EXD2DB10\EXD2DB10.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol5\EXD2DB10\Log"};
                DB13 = @{Name = "EXD2DB13"; EdbFilePath = "C:\mountpath\EXD2DBVol7\EXD2DB13\EXD2DB13.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol7\EXD2DB13\Log"};
                DB16 = @{Name = "EXD2DB16"; EdbFilePath = "C:\mountpath\EXD2DBVol8\EXD2DB16\EXD2DB16.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol8\EXD2DB16\Log"};
                DB19 = @{Name = "EXD2DB19"; EdbFilePath = "C:\mountpath\EXD2DBVol10\EXD2DB19\EXD2DB19.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol10\EXD2DB19\Log"};
                DB22 = @{Name = "EXD2DB22"; EdbFilePath = "C:\mountpath\EXD2DBVol11\EXD2DB22\EXD2DB22.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol11\EXD2DB22\Log"};
                DB25 = @{Name = "EXD2DB25"; EdbFilePath = "C:\mountpath\EXD2DBVol13\EXD2DB25\EXD2DB25.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol13\EXD2DB25\Log"};
                DB28 = @{Name = "EXD2DB28"; EdbFilePath = "C:\mountpath\EXD2DBVol14\EXD2DB28\EXD2DB28.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol14\EXD2DB28\Log"};
                DB31 = @{Name = "EXD2DB31"; EdbFilePath = "C:\mountpath\EXD2DBVol16\EXD2DB31\EXD2DB31.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol16\EXD2DB31\Log"};
                DB34 = @{Name = "EXD2DB34"; EdbFilePath = "C:\mountpath\EXD2DBVol17\EXD2DB34\EXD2DB34.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol17\EXD2DB34\Log"};
                DB37 = @{Name = "EXD2DB37"; EdbFilePath = "C:\mountpath\EXD2DBVol19\EXD2DB37\EXD2DB37.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol19\EXD2DB37\Log"};
                DB40 = @{Name = "EXD2DB40"; EdbFilePath = "C:\mountpath\EXD2DBVol20\EXD2DB40\EXD2DB40.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol20\EXD2DB40\Log"};
                DB43 = @{Name = "EXD2DB43"; EdbFilePath = "C:\mountpath\EXD2DBVol22\EXD2DB43\EXD2DB43.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol22\EXD2DB43\Log"};
                DB46 = @{Name = "EXD2DB46"; EdbFilePath = "C:\mountpath\EXD2DBVol23\EXD2DB46\EXD2DB46.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol23\EXD2DB46\Log"}
            }

            #Configure the copies next.
            CopyDBList    = @{
                DB2 = @{Name = "EXD2DB2"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB3 = @{Name = "EXD2DB3"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB5 = @{Name = "EXD2DB5"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB6 = @{Name = "EXD2DB6"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB8 = @{Name = "EXD2DB8"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB9 = @{Name = "EXD2DB9"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB11 = @{Name = "EXD2DB11"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB12 = @{Name = "EXD2DB12"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB14 = @{Name = "EXD2DB14"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB15 = @{Name = "EXD2DB15"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB17 = @{Name = "EXD2DB17"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB18 = @{Name = "EXD2DB18"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB20 = @{Name = "EXD2DB20"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB21 = @{Name = "EXD2DB21"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB23 = @{Name = "EXD2DB23"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB24 = @{Name = "EXD2DB24"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB26 = @{Name = "EXD2DB26"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB27 = @{Name = "EXD2DB27"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB29 = @{Name = "EXD2DB29"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB30 = @{Name = "EXD2DB30"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB32 = @{Name = "EXD2DB32"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB33 = @{Name = "EXD2DB33"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB35 = @{Name = "EXD2DB35"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB36 = @{Name = "EXD2DB36"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB38 = @{Name = "EXD2DB38"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB39 = @{Name = "EXD2DB39"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB41 = @{Name = "EXD2DB41"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB42 = @{Name = "EXD2DB42"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB44 = @{Name = "EXD2DB44"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB45 = @{Name = "EXD2DB45"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB47 = @{Name = "EXD2DB47"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB48 = @{Name = "EXD2DB48"; ActivationPreference = 3; ReplayLagTime = "00:00:00"}

            }
        }
        #dc-ex-d2-n2
        @{
            NodeName    = "dc-ex-d2-n2"
            Fqdn        = "dc-ex-d2-n2.domain.corp"
            IPAddress2000   = "10.34.3.234/22"
            Role        = "AdditionalDAGMember"
            PSDscAllowDomainUser = $true
            DAGId       = "EXD2"
            CASID       = "CAS1"
            #Configure the databases whose primary copies will reside on this server
            PrimaryDBList = @{
                DB2 = @{Name = "EXD2DB2"; EdbFilePath = "C:\mountpath\EXD2DBVol1\EXD2DB2\EXD2DB2.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol1\EXD2DB2\Log"};
                DB5 = @{Name = "EXD2DB5"; EdbFilePath = "C:\mountpath\EXD2DBVol3\EXD2DB5\EXD2DB5.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol3\EXD2DB5\Log"};
                DB8 = @{Name = "EXD2DB8"; EdbFilePath = "C:\mountpath\EXD2DBVol4\EXD2DB8\EXD2DB8.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol4\EXD2DB8\Log"};
                DB11 = @{Name = "EXD2DB11"; EdbFilePath = "C:\mountpath\EXD2DBVol6\EXD2DB11\EXD2DB11.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol6\EXD2DB11\Log"};
                DB14 = @{Name = "EXD2DB14"; EdbFilePath = "C:\mountpath\EXD2DBVol7\EXD2DB14\EXD2DB14.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol7\EXD2DB14\Log"};
                DB17 = @{Name = "EXD2DB17"; EdbFilePath = "C:\mountpath\EXD2DBVol9\EXD2DB17\EXD2DB17.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol9\EXD2DB17\Log"};
                DB20 = @{Name = "EXD2DB20"; EdbFilePath = "C:\mountpath\EXD2DBVol10\EXD2DB20\EXD2DB20.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol10\EXD2DB20\Log"};
                DB23 = @{Name = "EXD2DB23"; EdbFilePath = "C:\mountpath\EXD2DBVol12\EXD2DB23\EXD2DB23.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol12\EXD2DB23\Log"};
                DB26 = @{Name = "EXD2DB26"; EdbFilePath = "C:\mountpath\EXD2DBVol13\EXD2DB26\EXD2DB26.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol13\EXD2DB26\Log"};
                DB29 = @{Name = "EXD2DB29"; EdbFilePath = "C:\mountpath\EXD2DBVol15\EXD2DB29\EXD2DB29.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol15\EXD2DB29\Log"};
                DB32 = @{Name = "EXD2DB32"; EdbFilePath = "C:\mountpath\EXD2DBVol16\EXD2DB32\EXD2DB32.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol16\EXD2DB32\Log"};
                DB35 = @{Name = "EXD2DB35"; EdbFilePath = "C:\mountpath\EXD2DBVol18\EXD2DB35\EXD2DB35.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol18\EXD2DB35\Log"};
                DB38 = @{Name = "EXD2DB38"; EdbFilePath = "C:\mountpath\EXD2DBVol19\EXD2DB38\EXD2DB38.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol19\EXD2DB38\Log"};
                DB41 = @{Name = "EXD2DB41"; EdbFilePath = "C:\mountpath\EXD2DBVol21\EXD2DB41\EXD2DB41.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol21\EXD2DB41\Log"};
                DB44 = @{Name = "EXD2DB44"; EdbFilePath = "C:\mountpath\EXD2DBVol22\EXD2DB44\EXD2DB44.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol22\EXD2DB44\Log"};
                DB47 = @{Name = "EXD2DB47"; EdbFilePath = "C:\mountpath\EXD2DBVol24\EXD2DB47\EXD2DB47.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol24\EXD2DB47\Log"}
            }

            #Configure the copies next.
            CopyDBList    = @{
                DB1 = @{Name = "EXD2DB1"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB3 = @{Name = "EXD2DB3"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB4 = @{Name = "EXD2DB4"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB6 = @{Name = "EXD2DB6"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB7 = @{Name = "EXD2DB7"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB9 = @{Name = "EXD2DB9"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB10 = @{Name = "EXD2DB10"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB12 = @{Name = "EXD2DB12"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB13 = @{Name = "EXD2DB13"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB15 = @{Name = "EXD2DB15"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB16 = @{Name = "EXD2DB16"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB18 = @{Name = "EXD2DB18"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB19 = @{Name = "EXD2DB19"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB21 = @{Name = "EXD2DB21"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB22 = @{Name = "EXD2DB22"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB24 = @{Name = "EXD2DB24"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB25 = @{Name = "EXD2DB25"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB27 = @{Name = "EXD2DB27"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB28 = @{Name = "EXD2DB28"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB30 = @{Name = "EXD2DB30"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB31 = @{Name = "EXD2DB31"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB33 = @{Name = "EXD2DB33"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB34 = @{Name = "EXD2DB34"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB36 = @{Name = "EXD2DB36"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB37 = @{Name = "EXD2DB37"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB39 = @{Name = "EXD2DB39"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB40 = @{Name = "EXD2DB40"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB42 = @{Name = "EXD2DB42"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB43 = @{Name = "EXD2DB43"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB45 = @{Name = "EXD2DB45"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB46 = @{Name = "EXD2DB46"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB48 = @{Name = "EXD2DB48"; ActivationPreference = 2; ReplayLagTime = "00:00:00"}
            }
        }
        #dc-ex-d2-n3
        @{
            NodeName    = "dc-ex-d2-n3"
            Fqdn        = "dc-ex-d2-n3.domain.corp"
            IPAddress2000   = "10.34.3.235/22"
            Role        = "AdditionalDAGMember"
            PSDscAllowDomainUser = $true
            DAGId       = "EXD2"
            CASID       = "CAS1"
            PrimaryDBList = @{
                DB3 = @{Name = "EXD2DB3"; EdbFilePath = "C:\mountpath\EXD2DBVol2\EXD2DB3\EXD2DB3.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol2\EXD2DB3\Log"};
                DB6 = @{Name = "EXD2DB6"; EdbFilePath = "C:\mountpath\EXD2DBVol3\EXD2DB6\EXD2DB6.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol3\EXD2DB6\Log"};
                DB9 = @{Name = "EXD2DB9"; EdbFilePath = "C:\mountpath\EXD2DBVol5\EXD2DB9\EXD2DB9.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol5\EXD2DB9\Log"};
                DB12 = @{Name = "EXD2DB12"; EdbFilePath = "C:\mountpath\EXD2DBVol6\EXD2DB12\EXD2DB12.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol6\EXD2DB12\Log"};
                DB15 = @{Name = "EXD2DB15"; EdbFilePath = "C:\mountpath\EXD2DBVol8\EXD2DB15\EXD2DB15.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol8\EXD2DB15\Log"};
                DB18 = @{Name = "EXD2DB18"; EdbFilePath = "C:\mountpath\EXD2DBVol9\EXD2DB18\EXD2DB18.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol9\EXD2DB18\Log"};
                DB21 = @{Name = "EXD2DB21"; EdbFilePath = "C:\mountpath\EXD2DBVol11\EXD2DB21\EXD2DB21.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol11\EXD2DB21\Log"};
                DB24 = @{Name = "EXD2DB24"; EdbFilePath = "C:\mountpath\EXD2DBVol12\EXD2DB24\EXD2DB24.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol12\EXD2DB24\Log"};
                DB27 = @{Name = "EXD2DB27"; EdbFilePath = "C:\mountpath\EXD2DBVol14\EXD2DB27\EXD2DB27.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol14\EXD2DB27\Log"};
                DB30 = @{Name = "EXD2DB30"; EdbFilePath = "C:\mountpath\EXD2DBVol15\EXD2DB30\EXD2DB30.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol15\EXD2DB30\Log"};
                DB33 = @{Name = "EXD2DB33"; EdbFilePath = "C:\mountpath\EXD2DBVol17\EXD2DB33\EXD2DB33.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol17\EXD2DB33\Log"};
                DB36 = @{Name = "EXD2DB36"; EdbFilePath = "C:\mountpath\EXD2DBVol18\EXD2DB36\EXD2DB36.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol18\EXD2DB36\Log"};
                DB39 = @{Name = "EXD2DB39"; EdbFilePath = "C:\mountpath\EXD2DBVol20\EXD2DB39\EXD2DB39.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol20\EXD2DB39\Log"};
                DB42 = @{Name = "EXD2DB42"; EdbFilePath = "C:\mountpath\EXD2DBVol21\EXD2DB42\EXD2DB42.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol21\EXD2DB42\Log"};
                DB45 = @{Name = "EXD2DB45"; EdbFilePath = "C:\mountpath\EXD2DBVol23\EXD2DB45\EXD2DB45.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol23\EXD2DB45\Log"};
                DB48 = @{Name = "EXD2DB48"; EdbFilePath = "C:\mountpath\EXD2DBVol24\EXD2DB48\EXD2DB48.edb"; LogFolderPath = "C:\mountpath\EXD2DBVol24\EXD2DB48\Log"}
            }

            #Configure the copies next.
            CopyDBList    = @{
                DB1 = @{Name = "EXD2DB1"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB2 = @{Name = "EXD2DB2"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB4 = @{Name = "EXD2DB4"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB5 = @{Name = "EXD2DB5"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB7 = @{Name = "EXD2DB7"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB8 = @{Name = "EXD2DB8"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB10 = @{Name = "EXD2DB10"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB11 = @{Name = "EXD2DB11"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB13 = @{Name = "EXD2DB13"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB14 = @{Name = "EXD2DB14"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB16 = @{Name = "EXD2DB16"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB17 = @{Name = "EXD2DB17"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB19 = @{Name = "EXD2DB19"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB20 = @{Name = "EXD2DB20"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB22 = @{Name = "EXD2DB22"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB23 = @{Name = "EXD2DB23"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB25 = @{Name = "EXD2DB25"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB26 = @{Name = "EXD2DB26"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB28 = @{Name = "EXD2DB28"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB29 = @{Name = "EXD2DB29"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB31 = @{Name = "EXD2DB31"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB32 = @{Name = "EXD2DB32"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB34 = @{Name = "EXD2DB34"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB35 = @{Name = "EXD2DB35"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB37 = @{Name = "EXD2DB37"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB38 = @{Name = "EXD2DB38"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB40 = @{Name = "EXD2DB40"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB41 = @{Name = "EXD2DB41"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB43 = @{Name = "EXD2DB43"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB44 = @{Name = "EXD2DB44"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB46 = @{Name = "EXD2DB46"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB47 = @{Name = "EXD2DB47"; ActivationPreference = 3; ReplayLagTime = "00:00:00"}
            }
        }
        #dc-ex-d3-n1
        @{
            NodeName    = "dc-ex-d3-n1"
            Fqdn        = "dc-ex-d3-n1.domain.corp"
            IPAddress2000   = "10.34.3.236/22"
            Role        = "FirstDAGMember"
            PSDscAllowDomainUser = $true
            DAGId       = "EXD3" #Used to determine which DAG settings the servers should use. Corresponds to DAG1 hashtable entry below.
            CASId       = "CAS1" #Used to determine which CAS settings the server should use. Corresponds to CAS1 hashtable entry below.
            #Configure the databases whose primary copies will reside on this server
            PrimaryDBList = @{
                DB1 = @{Name = "EXD3DB1"; EdbFilePath = "C:\mountpath\EXD3DBVol1\EXD3DB1\EXD3DB1.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol1\EXD3DB1\Log"};
                DB4 = @{Name = "EXD3DB4"; EdbFilePath = "C:\mountpath\EXD3DBVol2\EXD3DB4\EXD3DB4.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol2\EXD3DB4\Log"};
                DB7 = @{Name = "EXD3DB7"; EdbFilePath = "C:\mountpath\EXD3DBVol4\EXD3DB7\EXD3DB7.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol4\EXD3DB7\Log"};
                DB10 = @{Name = "EXD3DB10"; EdbFilePath = "C:\mountpath\EXD3DBVol5\EXD3DB10\EXD3DB10.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol5\EXD3DB10\Log"};
                DB13 = @{Name = "EXD3DB13"; EdbFilePath = "C:\mountpath\EXD3DBVol7\EXD3DB13\EXD3DB13.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol7\EXD3DB13\Log"};
                DB16 = @{Name = "EXD3DB16"; EdbFilePath = "C:\mountpath\EXD3DBVol8\EXD3DB16\EXD3DB16.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol8\EXD3DB16\Log"};
                DB19 = @{Name = "EXD3DB19"; EdbFilePath = "C:\mountpath\EXD3DBVol10\EXD3DB19\EXD3DB19.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol10\EXD3DB19\Log"};
                DB22 = @{Name = "EXD3DB22"; EdbFilePath = "C:\mountpath\EXD3DBVol11\EXD3DB22\EXD3DB22.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol11\EXD3DB22\Log"};
                DB25 = @{Name = "EXD3DB25"; EdbFilePath = "C:\mountpath\EXD3DBVol13\EXD3DB25\EXD3DB25.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol13\EXD3DB25\Log"};
                DB28 = @{Name = "EXD3DB28"; EdbFilePath = "C:\mountpath\EXD3DBVol14\EXD3DB28\EXD3DB28.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol14\EXD3DB28\Log"};
                DB31 = @{Name = "EXD3DB31"; EdbFilePath = "C:\mountpath\EXD3DBVol16\EXD3DB31\EXD3DB31.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol16\EXD3DB31\Log"};
                DB34 = @{Name = "EXD3DB34"; EdbFilePath = "C:\mountpath\EXD3DBVol17\EXD3DB34\EXD3DB34.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol17\EXD3DB34\Log"};
                DB37 = @{Name = "EXD3DB37"; EdbFilePath = "C:\mountpath\EXD3DBVol19\EXD3DB37\EXD3DB37.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol19\EXD3DB37\Log"};
                DB40 = @{Name = "EXD3DB40"; EdbFilePath = "C:\mountpath\EXD3DBVol20\EXD3DB40\EXD3DB40.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol20\EXD3DB40\Log"};
                DB43 = @{Name = "EXD3DB43"; EdbFilePath = "C:\mountpath\EXD3DBVol22\EXD3DB43\EXD3DB43.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol22\EXD3DB43\Log"};
                DB46 = @{Name = "EXD3DB46"; EdbFilePath = "C:\mountpath\EXD3DBVol23\EXD3DB46\EXD3DB46.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol23\EXD3DB46\Log"}
            }

            #Configure the copies next.
            CopyDBList    = @{
                DB2 = @{Name = "EXD3DB2"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB3 = @{Name = "EXD3DB3"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB5 = @{Name = "EXD3DB5"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB6 = @{Name = "EXD3DB6"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB8 = @{Name = "EXD3DB8"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB9 = @{Name = "EXD3DB9"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB11 = @{Name = "EXD3DB11"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB12 = @{Name = "EXD3DB12"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB14 = @{Name = "EXD3DB14"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB15 = @{Name = "EXD3DB15"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB17 = @{Name = "EXD3DB17"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB18 = @{Name = "EXD3DB18"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB20 = @{Name = "EXD3DB20"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB21 = @{Name = "EXD3DB21"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB23 = @{Name = "EXD3DB23"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB24 = @{Name = "EXD3DB24"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB26 = @{Name = "EXD3DB26"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB27 = @{Name = "EXD3DB27"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB29 = @{Name = "EXD3DB29"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB30 = @{Name = "EXD3DB30"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB32 = @{Name = "EXD3DB32"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB33 = @{Name = "EXD3DB33"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB35 = @{Name = "EXD3DB35"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB36 = @{Name = "EXD3DB36"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB38 = @{Name = "EXD3DB38"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB39 = @{Name = "EXD3DB39"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB41 = @{Name = "EXD3DB41"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB42 = @{Name = "EXD3DB42"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB44 = @{Name = "EXD3DB44"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB45 = @{Name = "EXD3DB45"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB47 = @{Name = "EXD3DB47"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB48 = @{Name = "EXD3DB48"; ActivationPreference = 3; ReplayLagTime = "00:00:00"}
            }
        }
        #dc-ex-d3-n2
        @{
            NodeName    = "dc-ex-d3-n2"
            Fqdn        = "dc-ex-d3-n2.domain.corp"
            IPAddress2000   = "10.34.3.237/22"
            Role        = "AdditionalDAGMember"
            PSDscAllowDomainUser = $true
            DAGId       = "EXD3"
            CASID       = "CAS1"
            #Configure the databases whose primary copies will reside on this server
            PrimaryDBList = @{
                DB2 = @{Name = "EXD3DB2"; EdbFilePath = "C:\mountpath\EXD3DBVol1\EXD3DB2\EXD3DB2.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol1\EXD3DB2\Log"};
                DB5 = @{Name = "EXD3DB5"; EdbFilePath = "C:\mountpath\EXD3DBVol3\EXD3DB5\EXD3DB5.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol3\EXD3DB5\Log"};
                DB8 = @{Name = "EXD3DB8"; EdbFilePath = "C:\mountpath\EXD3DBVol4\EXD3DB8\EXD3DB8.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol4\EXD3DB8\Log"};
                DB11 = @{Name = "EXD3DB11"; EdbFilePath = "C:\mountpath\EXD3DBVol6\EXD3DB11\EXD3DB11.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol6\EXD3DB11\Log"};
                DB14 = @{Name = "EXD3DB14"; EdbFilePath = "C:\mountpath\EXD3DBVol7\EXD3DB14\EXD3DB14.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol7\EXD3DB14\Log"};
                DB17 = @{Name = "EXD3DB17"; EdbFilePath = "C:\mountpath\EXD3DBVol9\EXD3DB17\EXD3DB17.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol9\EXD3DB17\Log"};
                DB20 = @{Name = "EXD3DB20"; EdbFilePath = "C:\mountpath\EXD3DBVol10\EXD3DB20\EXD3DB20.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol10\EXD3DB20\Log"};
                DB23 = @{Name = "EXD3DB23"; EdbFilePath = "C:\mountpath\EXD3DBVol12\EXD3DB23\EXD3DB23.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol12\EXD3DB23\Log"};
                DB26 = @{Name = "EXD3DB26"; EdbFilePath = "C:\mountpath\EXD3DBVol13\EXD3DB26\EXD3DB26.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol13\EXD3DB26\Log"};
                DB29 = @{Name = "EXD3DB29"; EdbFilePath = "C:\mountpath\EXD3DBVol15\EXD3DB29\EXD3DB29.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol15\EXD3DB29\Log"};
                DB32 = @{Name = "EXD3DB32"; EdbFilePath = "C:\mountpath\EXD3DBVol16\EXD3DB32\EXD3DB32.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol16\EXD3DB32\Log"};
                DB35 = @{Name = "EXD3DB35"; EdbFilePath = "C:\mountpath\EXD3DBVol18\EXD3DB35\EXD3DB35.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol18\EXD3DB35\Log"};
                DB38 = @{Name = "EXD3DB38"; EdbFilePath = "C:\mountpath\EXD3DBVol19\EXD3DB38\EXD3DB38.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol19\EXD3DB38\Log"};
                DB41 = @{Name = "EXD3DB41"; EdbFilePath = "C:\mountpath\EXD3DBVol21\EXD3DB41\EXD3DB41.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol21\EXD3DB41\Log"};
                DB44 = @{Name = "EXD3DB44"; EdbFilePath = "C:\mountpath\EXD3DBVol22\EXD3DB44\EXD3DB44.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol22\EXD3DB44\Log"};
                DB47 = @{Name = "EXD3DB47"; EdbFilePath = "C:\mountpath\EXD3DBVol24\EXD3DB47\EXD3DB47.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol24\EXD3DB47\Log"}
            }

            #Configure the copies next.
            CopyDBList    = @{
                DB1 = @{Name = "EXD3DB1"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB3 = @{Name = "EXD3DB3"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB4 = @{Name = "EXD3DB4"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB6 = @{Name = "EXD3DB6"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB7 = @{Name = "EXD3DB7"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB9 = @{Name = "EXD3DB9"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB10 = @{Name = "EXD3DB10"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB12 = @{Name = "EXD3DB12"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB13 = @{Name = "EXD3DB13"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB15 = @{Name = "EXD3DB15"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB16 = @{Name = "EXD3DB16"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB18 = @{Name = "EXD3DB18"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB19 = @{Name = "EXD3DB19"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB21 = @{Name = "EXD3DB21"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB22 = @{Name = "EXD3DB22"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB24 = @{Name = "EXD3DB24"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB25 = @{Name = "EXD3DB25"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB27 = @{Name = "EXD3DB27"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB28 = @{Name = "EXD3DB28"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB30 = @{Name = "EXD3DB30"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB31 = @{Name = "EXD3DB31"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB33 = @{Name = "EXD3DB33"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB34 = @{Name = "EXD3DB34"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB36 = @{Name = "EXD3DB36"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB37 = @{Name = "EXD3DB37"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB39 = @{Name = "EXD3DB39"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB40 = @{Name = "EXD3DB40"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB42 = @{Name = "EXD3DB42"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB43 = @{Name = "EXD3DB43"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB45 = @{Name = "EXD3DB45"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB46 = @{Name = "EXD3DB46"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB48 = @{Name = "EXD3DB48"; ActivationPreference = 2; ReplayLagTime = "00:00:00"}
            }
        }
        #dc-ex-d3-n3
        @{
            NodeName    = "dc-ex-d3-n3"
            Fqdn        = "dc-ex-d3-n3.domain.corp"
            IPAddress2000   = "10.34.3.238/22"
            Role        = "AdditionalDAGMember"
            PSDscAllowDomainUser = $true
            DAGId       = "EXD3"
            CASID       = "CAS1"
            #Configure the databases whose primary copies will reside on this server
            PrimaryDBList = @{
                DB3 = @{Name = "EXD3DB3"; EdbFilePath = "C:\mountpath\EXD3DBVol2\EXD3DB3\EXD3DB3.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol2\EXD3DB3\Log"};
                DB6 = @{Name = "EXD3DB6"; EdbFilePath = "C:\mountpath\EXD3DBVol3\EXD3DB6\EXD3DB6.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol3\EXD3DB6\Log"};
                DB9 = @{Name = "EXD3DB9"; EdbFilePath = "C:\mountpath\EXD3DBVol5\EXD3DB9\EXD3DB9.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol5\EXD3DB9\Log"};
                DB12 = @{Name = "EXD3DB12"; EdbFilePath = "C:\mountpath\EXD3DBVol6\EXD3DB12\EXD3DB12.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol6\EXD3DB12\Log"};
                DB15 = @{Name = "EXD3DB15"; EdbFilePath = "C:\mountpath\EXD3DBVol8\EXD3DB15\EXD3DB15.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol8\EXD3DB15\Log"};
                DB18 = @{Name = "EXD3DB18"; EdbFilePath = "C:\mountpath\EXD3DBVol9\EXD3DB18\EXD3DB18.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol9\EXD3DB18\Log"};
                DB21 = @{Name = "EXD3DB21"; EdbFilePath = "C:\mountpath\EXD3DBVol11\EXD3DB21\EXD3DB21.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol11\EXD3DB21\Log"};
                DB24 = @{Name = "EXD3DB24"; EdbFilePath = "C:\mountpath\EXD3DBVol12\EXD3DB24\EXD3DB24.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol12\EXD3DB24\Log"};
                DB27 = @{Name = "EXD3DB27"; EdbFilePath = "C:\mountpath\EXD3DBVol14\EXD3DB27\EXD3DB27.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol14\EXD3DB27\Log"};
                DB30 = @{Name = "EXD3DB30"; EdbFilePath = "C:\mountpath\EXD3DBVol15\EXD3DB30\EXD3DB30.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol15\EXD3DB30\Log"};
                DB33 = @{Name = "EXD3DB33"; EdbFilePath = "C:\mountpath\EXD3DBVol17\EXD3DB33\EXD3DB33.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol17\EXD3DB33\Log"};
                DB36 = @{Name = "EXD3DB36"; EdbFilePath = "C:\mountpath\EXD3DBVol18\EXD3DB36\EXD3DB36.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol18\EXD3DB36\Log"};
                DB39 = @{Name = "EXD3DB39"; EdbFilePath = "C:\mountpath\EXD3DBVol20\EXD3DB39\EXD3DB39.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol20\EXD3DB39\Log"};
                DB42 = @{Name = "EXD3DB42"; EdbFilePath = "C:\mountpath\EXD3DBVol21\EXD3DB42\EXD3DB42.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol21\EXD3DB42\Log"};
                DB45 = @{Name = "EXD3DB45"; EdbFilePath = "C:\mountpath\EXD3DBVol23\EXD3DB45\EXD3DB45.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol23\EXD3DB45\Log"};
                DB48 = @{Name = "EXD3DB48"; EdbFilePath = "C:\mountpath\EXD3DBVol24\EXD3DB48\EXD3DB48.edb"; LogFolderPath = "C:\mountpath\EXD3DBVol24\EXD3DB48\Log"}
            }

            #Configure the copies next.
            CopyDBList    = @{
                DB1 = @{Name = "EXD3DB1"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB2 = @{Name = "EXD3DB2"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB4 = @{Name = "EXD3DB4"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB5 = @{Name = "EXD3DB5"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB7 = @{Name = "EXD3DB7"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB8 = @{Name = "EXD3DB8"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB10 = @{Name = "EXD3DB10"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB11 = @{Name = "EXD3DB11"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB13 = @{Name = "EXD3DB13"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB14 = @{Name = "EXD3DB14"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB16 = @{Name = "EXD3DB16"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB17 = @{Name = "EXD3DB17"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB19 = @{Name = "EXD3DB19"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB20 = @{Name = "EXD3DB20"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB22 = @{Name = "EXD3DB22"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB23 = @{Name = "EXD3DB23"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB25 = @{Name = "EXD3DB25"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB26 = @{Name = "EXD3DB26"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB28 = @{Name = "EXD3DB28"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB29 = @{Name = "EXD3DB29"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB31 = @{Name = "EXD3DB31"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB32 = @{Name = "EXD3DB32"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB34 = @{Name = "EXD3DB34"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB35 = @{Name = "EXD3DB35"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB37 = @{Name = "EXD3DB37"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB38 = @{Name = "EXD3DB38"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB40 = @{Name = "EXD3DB40"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB41 = @{Name = "EXD3DB41"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB43 = @{Name = "EXD3DB43"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB44 = @{Name = "EXD3DB44"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB46 = @{Name = "EXD3DB46"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB47 = @{Name = "EXD3DB47"; ActivationPreference = 3; ReplayLagTime = "00:00:00"}
            }
        }
        #dc-ex-d4-n1
        @{
            NodeName    = "dc-ex-d4-n1"
            Fqdn        = "dc-ex-d4-n1.domain.corp"
            IPAddress2000   = "10.34.3.239/22"
            Role        = "FirstDAGMember"
            PSDscAllowDomainUser = $true
            DAGId       = "EXD4" #Used to determine which DAG settings the servers should use. Corresponds to DAG1 hashtable entry below.
            CASId       = "CAS1" #Used to determine which CAS settings the server should use. Corresponds to CAS1 hashtable entry below.
            #Configure the databases whose primary copies will reside on this server
            PrimaryDBList = @{
                DB1 = @{Name = "EXD4DB1"; EdbFilePath = "C:\mountpath\EXD4DBVol1\EXD4DB1\EXD4DB1.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol1\EXD4DB1\Log"};
                DB4 = @{Name = "EXD4DB4"; EdbFilePath = "C:\mountpath\EXD4DBVol2\EXD4DB4\EXD4DB4.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol2\EXD4DB4\Log"};
                DB7 = @{Name = "EXD4DB7"; EdbFilePath = "C:\mountpath\EXD4DBVol4\EXD4DB7\EXD4DB7.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol4\EXD4DB7\Log"};
                DB10 = @{Name = "EXD4DB10"; EdbFilePath = "C:\mountpath\EXD4DBVol5\EXD4DB10\EXD4DB10.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol5\EXD4DB10\Log"};
                DB13 = @{Name = "EXD4DB13"; EdbFilePath = "C:\mountpath\EXD4DBVol7\EXD4DB13\EXD4DB13.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol7\EXD4DB13\Log"};
                DB16 = @{Name = "EXD4DB16"; EdbFilePath = "C:\mountpath\EXD4DBVol8\EXD4DB16\EXD4DB16.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol8\EXD4DB16\Log"};
                DB19 = @{Name = "EXD4DB19"; EdbFilePath = "C:\mountpath\EXD4DBVol10\EXD4DB19\EXD4DB19.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol10\EXD4DB19\Log"};
                DB22 = @{Name = "EXD4DB22"; EdbFilePath = "C:\mountpath\EXD4DBVol11\EXD4DB22\EXD4DB22.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol11\EXD4DB22\Log"};
                DB25 = @{Name = "EXD4DB25"; EdbFilePath = "C:\mountpath\EXD4DBVol13\EXD4DB25\EXD4DB25.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol13\EXD4DB25\Log"};
                DB28 = @{Name = "EXD4DB28"; EdbFilePath = "C:\mountpath\EXD4DBVol14\EXD4DB28\EXD4DB28.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol14\EXD4DB28\Log"};
                DB31 = @{Name = "EXD4DB31"; EdbFilePath = "C:\mountpath\EXD4DBVol16\EXD4DB31\EXD4DB31.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol16\EXD4DB31\Log"};
                DB34 = @{Name = "EXD4DB34"; EdbFilePath = "C:\mountpath\EXD4DBVol17\EXD4DB34\EXD4DB34.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol17\EXD4DB34\Log"};
                DB37 = @{Name = "EXD4DB37"; EdbFilePath = "C:\mountpath\EXD4DBVol19\EXD4DB37\EXD4DB37.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol19\EXD4DB37\Log"};
                DB40 = @{Name = "EXD4DB40"; EdbFilePath = "C:\mountpath\EXD4DBVol20\EXD4DB40\EXD4DB40.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol20\EXD4DB40\Log"};
                DB43 = @{Name = "EXD4DB43"; EdbFilePath = "C:\mountpath\EXD4DBVol22\EXD4DB43\EXD4DB43.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol22\EXD4DB43\Log"};
                DB46 = @{Name = "EXD4DB46"; EdbFilePath = "C:\mountpath\EXD4DBVol23\EXD4DB46\EXD4DB46.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol23\EXD4DB46\Log"}
            }

            #Configure the copies next.
            CopyDBList    = @{
                DB2 = @{Name = "EXD4DB2"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB3 = @{Name = "EXD4DB3"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB5 = @{Name = "EXD4DB5"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB6 = @{Name = "EXD4DB6"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB8 = @{Name = "EXD4DB8"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB9 = @{Name = "EXD4DB9"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB11 = @{Name = "EXD4DB11"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB12 = @{Name = "EXD4DB12"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB14 = @{Name = "EXD4DB14"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB15 = @{Name = "EXD4DB15"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB17 = @{Name = "EXD4DB17"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB18 = @{Name = "EXD4DB18"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB20 = @{Name = "EXD4DB20"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB21 = @{Name = "EXD4DB21"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB23 = @{Name = "EXD4DB23"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB24 = @{Name = "EXD4DB24"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB26 = @{Name = "EXD4DB26"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB27 = @{Name = "EXD4DB27"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB29 = @{Name = "EXD4DB29"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB30 = @{Name = "EXD4DB30"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB32 = @{Name = "EXD4DB32"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB33 = @{Name = "EXD4DB33"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB35 = @{Name = "EXD4DB35"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB36 = @{Name = "EXD4DB36"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB38 = @{Name = "EXD4DB38"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB39 = @{Name = "EXD4DB39"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB41 = @{Name = "EXD4DB41"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB42 = @{Name = "EXD4DB42"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB44 = @{Name = "EXD4DB44"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB45 = @{Name = "EXD4DB45"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB47 = @{Name = "EXD4DB47"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB48 = @{Name = "EXD4DB48"; ActivationPreference = 3; ReplayLagTime = "00:00:00"}
            }
        }
        #dc-ex-d4-n2
        @{
            NodeName    = "dc-ex-d4-n2"
            Fqdn        = "dc-ex-d4-n2.domain.corp"
            IPAddress2000   = "10.34.3.240/22"
            Role        = "AdditionalDAGMember"
            PSDscAllowDomainUser = $true
            DAGId       = "EXD4"
            CASID       = "CAS1"
            #Configure the databases whose primary copies will reside on this server
            PrimaryDBList = @{
                DB2 = @{Name = "EXD4DB2"; EdbFilePath = "C:\mountpath\EXD4DBVol1\EXD4DB2\EXD4DB2.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol1\EXD4DB2\Log"};
                DB5 = @{Name = "EXD4DB5"; EdbFilePath = "C:\mountpath\EXD4DBVol3\EXD4DB5\EXD4DB5.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol3\EXD4DB5\Log"};
                DB8 = @{Name = "EXD4DB8"; EdbFilePath = "C:\mountpath\EXD4DBVol4\EXD4DB8\EXD4DB8.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol4\EXD4DB8\Log"};
                DB11 = @{Name = "EXD4DB11"; EdbFilePath = "C:\mountpath\EXD4DBVol6\EXD4DB11\EXD4DB11.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol6\EXD4DB11\Log"};
                DB14 = @{Name = "EXD4DB14"; EdbFilePath = "C:\mountpath\EXD4DBVol7\EXD4DB14\EXD4DB14.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol7\EXD4DB14\Log"};
                DB17 = @{Name = "EXD4DB17"; EdbFilePath = "C:\mountpath\EXD4DBVol9\EXD4DB17\EXD4DB17.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol9\EXD4DB17\Log"};
                DB20 = @{Name = "EXD4DB20"; EdbFilePath = "C:\mountpath\EXD4DBVol10\EXD4DB20\EXD4DB20.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol10\EXD4DB20\Log"};
                DB23 = @{Name = "EXD4DB23"; EdbFilePath = "C:\mountpath\EXD4DBVol12\EXD4DB23\EXD4DB23.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol12\EXD4DB23\Log"};
                DB26 = @{Name = "EXD4DB26"; EdbFilePath = "C:\mountpath\EXD4DBVol13\EXD4DB26\EXD4DB26.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol13\EXD4DB26\Log"};
                DB29 = @{Name = "EXD4DB29"; EdbFilePath = "C:\mountpath\EXD4DBVol15\EXD4DB29\EXD4DB29.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol15\EXD4DB29\Log"};
                DB32 = @{Name = "EXD4DB32"; EdbFilePath = "C:\mountpath\EXD4DBVol16\EXD4DB32\EXD4DB32.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol16\EXD4DB32\Log"};
                DB35 = @{Name = "EXD4DB35"; EdbFilePath = "C:\mountpath\EXD4DBVol18\EXD4DB35\EXD4DB35.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol18\EXD4DB35\Log"};
                DB38 = @{Name = "EXD4DB38"; EdbFilePath = "C:\mountpath\EXD4DBVol19\EXD4DB38\EXD4DB38.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol19\EXD4DB38\Log"};
                DB41 = @{Name = "EXD4DB41"; EdbFilePath = "C:\mountpath\EXD4DBVol21\EXD4DB41\EXD4DB41.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol21\EXD4DB41\Log"};
                DB44 = @{Name = "EXD4DB44"; EdbFilePath = "C:\mountpath\EXD4DBVol22\EXD4DB44\EXD4DB44.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol22\EXD4DB44\Log"};
                DB47 = @{Name = "EXD4DB47"; EdbFilePath = "C:\mountpath\EXD4DBVol24\EXD4DB47\EXD4DB47.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol24\EXD4DB47\Log"}
            }

            #Configure the copies next.
            CopyDBList    = @{
                DB1 = @{Name = "EXD4DB1"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB3 = @{Name = "EXD4DB3"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB4 = @{Name = "EXD4DB4"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB6 = @{Name = "EXD4DB6"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB7 = @{Name = "EXD4DB7"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB9 = @{Name = "EXD4DB9"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB10 = @{Name = "EXD4DB10"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB12 = @{Name = "EXD4DB12"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB13 = @{Name = "EXD4DB13"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB15 = @{Name = "EXD4DB15"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB16 = @{Name = "EXD4DB16"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB18 = @{Name = "EXD4DB18"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB19 = @{Name = "EXD4DB19"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB21 = @{Name = "EXD4DB21"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB22 = @{Name = "EXD4DB22"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB24 = @{Name = "EXD4DB24"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB25 = @{Name = "EXD4DB25"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB27 = @{Name = "EXD4DB27"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB28 = @{Name = "EXD4DB28"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB30 = @{Name = "EXD4DB30"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB31 = @{Name = "EXD4DB31"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB33 = @{Name = "EXD4DB33"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB34 = @{Name = "EXD4DB34"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB36 = @{Name = "EXD4DB36"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB37 = @{Name = "EXD4DB37"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB39 = @{Name = "EXD4DB39"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB40 = @{Name = "EXD4DB40"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB42 = @{Name = "EXD4DB42"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB43 = @{Name = "EXD4DB43"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB45 = @{Name = "EXD4DB45"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB46 = @{Name = "EXD4DB46"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB48 = @{Name = "EXD4DB48"; ActivationPreference = 2; ReplayLagTime = "00:00:00"}
            }
        }
        #dc-ex-d4-n3
        @{
            NodeName    = "dc-ex-d4-n3"
            Fqdn        = "dc-ex-d4-n3.domain.corp"
            IPAddress2000   = "10.34.3.241/22"
            Role        = "AdditionalDAGMember"
            PSDscAllowDomainUser = $true
            DAGId       = "EXD4"
            CASID       = "CAS1"
            #Configure the databases whose primary copies will reside on this server
            PrimaryDBList = @{
                DB3 = @{Name = "EXD4DB3"; EdbFilePath = "C:\mountpath\EXD4DBVol2\EXD4DB3\EXD4DB3.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol2\EXD4DB3\Log"};
                DB6 = @{Name = "EXD4DB6"; EdbFilePath = "C:\mountpath\EXD4DBVol3\EXD4DB6\EXD4DB6.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol3\EXD4DB6\Log"};
                DB9 = @{Name = "EXD4DB9"; EdbFilePath = "C:\mountpath\EXD4DBVol5\EXD4DB9\EXD4DB9.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol5\EXD4DB9\Log"};
                DB12 = @{Name = "EXD4DB12"; EdbFilePath = "C:\mountpath\EXD4DBVol6\EXD4DB12\EXD4DB12.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol6\EXD4DB12\Log"};
                DB15 = @{Name = "EXD4DB15"; EdbFilePath = "C:\mountpath\EXD4DBVol8\EXD4DB15\EXD4DB15.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol8\EXD4DB15\Log"};
                DB18 = @{Name = "EXD4DB18"; EdbFilePath = "C:\mountpath\EXD4DBVol9\EXD4DB18\EXD4DB18.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol9\EXD4DB18\Log"};
                DB21 = @{Name = "EXD4DB21"; EdbFilePath = "C:\mountpath\EXD4DBVol11\EXD4DB21\EXD4DB21.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol11\EXD4DB21\Log"};
                DB24 = @{Name = "EXD4DB24"; EdbFilePath = "C:\mountpath\EXD4DBVol12\EXD4DB24\EXD4DB24.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol12\EXD4DB24\Log"};
                DB27 = @{Name = "EXD4DB27"; EdbFilePath = "C:\mountpath\EXD4DBVol14\EXD4DB27\EXD4DB27.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol14\EXD4DB27\Log"};
                DB30 = @{Name = "EXD4DB30"; EdbFilePath = "C:\mountpath\EXD4DBVol15\EXD4DB30\EXD4DB30.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol15\EXD4DB30\Log"};
                DB33 = @{Name = "EXD4DB33"; EdbFilePath = "C:\mountpath\EXD4DBVol17\EXD4DB33\EXD4DB33.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol17\EXD4DB33\Log"};
                DB36 = @{Name = "EXD4DB36"; EdbFilePath = "C:\mountpath\EXD4DBVol18\EXD4DB36\EXD4DB36.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol18\EXD4DB36\Log"};
                DB39 = @{Name = "EXD4DB39"; EdbFilePath = "C:\mountpath\EXD4DBVol20\EXD4DB39\EXD4DB39.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol20\EXD4DB39\Log"};
                DB42 = @{Name = "EXD4DB42"; EdbFilePath = "C:\mountpath\EXD4DBVol21\EXD4DB42\EXD4DB42.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol21\EXD4DB42\Log"};
                DB45 = @{Name = "EXD4DB45"; EdbFilePath = "C:\mountpath\EXD4DBVol23\EXD4DB45\EXD4DB45.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol23\EXD4DB45\Log"};
                DB48 = @{Name = "EXD4DB48"; EdbFilePath = "C:\mountpath\EXD4DBVol24\EXD4DB48\EXD4DB48.edb"; LogFolderPath = "C:\mountpath\EXD4DBVol24\EXD4DB48\Log"}
            }

            #Configure the copies next.
            CopyDBList    = @{
                DB1 = @{Name = "EXD4DB1"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB2 = @{Name = "EXD4DB2"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB4 = @{Name = "EXD4DB4"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB5 = @{Name = "EXD4DB5"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB7 = @{Name = "EXD4DB7"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB8 = @{Name = "EXD4DB8"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB10 = @{Name = "EXD4DB10"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB11 = @{Name = "EXD4DB11"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB13 = @{Name = "EXD4DB13"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB14 = @{Name = "EXD4DB14"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB16 = @{Name = "EXD4DB16"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB17 = @{Name = "EXD4DB17"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB19 = @{Name = "EXD4DB19"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB20 = @{Name = "EXD4DB20"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB22 = @{Name = "EXD4DB22"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB23 = @{Name = "EXD4DB23"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB25 = @{Name = "EXD4DB25"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB26 = @{Name = "EXD4DB26"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB28 = @{Name = "EXD4DB28"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB29 = @{Name = "EXD4DB29"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB31 = @{Name = "EXD4DB31"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB32 = @{Name = "EXD4DB32"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB34 = @{Name = "EXD4DB34"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB35 = @{Name = "EXD4DB35"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB37 = @{Name = "EXD4DB37"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB38 = @{Name = "EXD4DB38"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB40 = @{Name = "EXD4DB40"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB41 = @{Name = "EXD4DB41"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB43 = @{Name = "EXD4DB43"; ActivationPreference = 3; ReplayLagTime = "00:00:00"};
                DB44 = @{Name = "EXD4DB44"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB46 = @{Name = "EXD4DB46"; ActivationPreference = 2; ReplayLagTime = "00:00:00"};
                DB47 = @{Name = "EXD4DB47"; ActivationPreference = 3; ReplayLagTime = "00:00:00"}
            }
        }
    );

    #Settings that are unique per DAG will go in separate hash table entries.
    EXD1 = @(
        @{
            ###DAG Settings###
            DAGName                              = "EXD1"           
            DatabaseAvailabilityGroupIPAddresses = "255.255.255.255"
            SkipDagValidation                    = $false
            WitnessServer                        = "vm-wit1.domain.corp"
            WitnessDirectory                     = "c:\ExDAGWitness\EXD1"
            AlternateWitnessServer               = "other-vm-wit1.domain.corp"
            AlternateWitnessDirectory            = "C:\ExDAGWitness\EXD1"
            AllowExtraServices                   = $true

            #xDatabaseAvailabilityGroupNetwork params
            #New network params
            DAGNet1NetworkName                   = "MapiDagNetwork"
            DAGNet1ReplicationEnabled            = $true
            DAGNet1Subnets                       = "10.34.0.0/22"

            #Certificate Settings
            Thumbprint                           = '2ECE681BC984F798D62C7E067F676D3F47CD8DA7'
            CertFilePath                         = "\\path\to\exchange\cert.pfx"
            Services                             = "IIS","POP","IMAP","SMTP"
        }
    );
    EXD2 = @(
        @{
            ###DAG Settings###
            DAGName                              = "EXD2"           
            DatabaseAvailabilityGroupIPAddresses = "255.255.255.255"    
            ManualDagNetworkConfiguration        = $true
            SkipDagValidation                    = $false
            WitnessServer                        = "vm-wit1.domain.corp"
            WitnessDirectory                     = "c:\ExDAGWitness\EXD2"
            AlternateWitnessServer               = "other-vm-wit1.domain.corp"
            AlternateWitnessDirectory            = "C:\ExDAGWitness\EXD2"
            AllowExtraServices                   = $true

            #xDatabaseAvailabilityGroupNetwork params
            #New network params
            DAGNet1NetworkName                   = "MapiDagNetwork"
            DAGNet1ReplicationEnabled            = $true
            DAGNet1Subnets                       = "10.34.0.0/22"

            #Certificate Settings
            Thumbprint                           = '2ECE681BC984F798D62C7E067F676D3F47CD8DA7'
            CertFilePath                         = "\\path\to\exchange\cert.pfx"
            Services                             = "IIS","POP","IMAP","SMTP"
        }
    );
    EXD3 = @(
        @{
            ###DAG Settings###
            DAGName                              = "EXD3"           
            DatabaseAvailabilityGroupIPAddresses = "255.255.255.255"    
            ManualDagNetworkConfiguration        = $true
            SkipDagValidation                    = $false
            WitnessServer                        = "vm-wit1.domain.corp"
            WitnessDirectory                     = "c:\ExDAGWitness\EXD3"
            AlternateWitnessServer               = "other-vm-wit1.domain.corp"
            AlternateWitnessDirectory            = "C:\ExDAGWitness\EXD3"
            AllowExtraServices                   = $true

            #xDatabaseAvailabilityGroupNetwork params
            #New network params
            DAGNet1NetworkName                   = "MapiDagNetwork"
            DAGNet1ReplicationEnabled            = $true
            DAGNet1Subnets                       = "10.34.0.0/22"

            #Certificate Settings
            Thumbprint                           = '2ECE681BC984F798D62C7E067F676D3F47CD8DA7'
            CertFilePath                         = "\\path\to\exchange\cert.pfx"
            Services                             = "IIS","POP","IMAP","SMTP"
        }
        
    );
    EXD4 = @(
        @{
            ###DAG Settings###
            DAGName                              = "EXD4"           
            DatabaseAvailabilityGroupIPAddresses = "255.255.255.255"    
            ManualDagNetworkConfiguration        = $true
            SkipDagValidation                    = $false
            WitnessServer                        = "vm-wit1.domain.corp"
            WitnessDirectory                     = "c:\ExDAGWitness\EXD4"
            AlternateWitnessServer               = "other-vm-wit1.domain.corp"
            AlternateWitnessDirectory            = "C:\ExDAGWitness\EXD4"
            AllowExtraServices                   = $true

            #xDatabaseAvailabilityGroupNetwork params
            #New network params
            DAGNet1NetworkName                   = "MapiDagNetwork"
            DAGNet1ReplicationEnabled            = $true
            DAGNet1Subnets                       = "10.34.0.0/22"

            #Certificate Settings
            Thumbprint                           = '2ECE681BC984F798D62C7E067F676D3F47CD8DA7'
            CertFilePath                         = "\\path\to\exchange\cert.pfx"
            Services                             = "IIS","POP","IMAP","SMTP"
        }
    );

    #CAS settings that are unique per site will go in separate hash table entries as well.
    CAS1 = @(
        @{
            InternalNLBFqdn            = "outlook.domain.corp"
            ExternalNLBFqdn            = "mail.domain.com"
            AutoDiscoverURL            = "autodiscover.domain.corp"

            #ClientAccessServer Settings
            AutoDiscoverSiteScope      = "DefaultSite1"

            #OAB Settings
            OABsToDistribute           = "Offline Address Book (Ex2013)"

            #ADFS Cert Settings
            ADFSSigningThumbprint      = "f2da12ed0dd3ad8f47c67d33bd10b3d23eb60754"
            ADFSSigningPath            = "\\filer1\ist\kbickmore\Certificates\adfs_signing.cer"

            #OWA Settings
            InstantMessagingServerName = "skype.domain.corp"
            IMCertificateThumbprint    = '2ECE681BC984F798D62C7E067F676D3F47CD8DA7'
            WacDiscoveryEndpoint       = 'https://oos.domain.corp/hosting/discovery'
        }
    );
}
