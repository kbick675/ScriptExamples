@{
    AllNodes = @(
        #Settings in this section will apply to all nodes. For the purposes of this demo,
        #the only thing that will be configured in here is how credentials will be stored
        #in the compiled MOF files.
        @{
            NodeName                    = "*"
            PSDscAllowPlainTextPassword = $true
        }
        @{
            NodeName                    = "phitedb1"
            NodeNameFQDN                = "phitedb1.vcaantech.com"
            Role                        = "FirstServerNode"
            InterfaceAlias              = "Ethernet0 2"
            IPAddress                   = "10.200.170.40/24"
            ClusterId                   = "ClusterInfo"
            CommonConfig                = "CommonItems"
        }
        @{
            NodeName                    = "phitedb2"
            NodeNameFQDN                = "phitedb2.vcaantech.com"
            Role                        = "AdditionalServerNode"
            InterfaceAlias              = "Ethernet0 2"
            IPAddress                   = "10.200.170.41/24"
            ClusterId                   = "ClusterInfo"
            CommonConfig                = "CommonItems"
        }
        @{
            NodeName                    = 'phiters1'
            NodeNameFQDN                = "pheiters1.vcaantech.com"
            Role                        = 'RS'
            InterfaceAlias              = "Ethernet0 2"
            IPAddress                   = "10.200.170.42/24"
            CommonConfig                = "CommonItems"
        }
    );
    CommonItems = @(
        @{
            GateWay                     = "10.200.170.1"
            DNSServer1                  = "10.211.102.100"
            DNSServer2                  = "10.125.105.100"
        }
    );
    ClusterInfo = @(
        @{
            ClusterName                 = "phitedbcl2"
            ClusterIP                   = '10.200.170.37'
            WSFCName                    = "phitewsfc1"
            WSFCIP                      = "10.200.170.39"
            StorageAccountAccessKey     = ""
            StorageAccount              = "vcawsfcwitness"
        }
    );
    SQLInstance = @(
        @{
            InstanceName           = 'MSSQLSERVER'
            SQLInstanceExe         = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Binn\sqlservr.exe'
            Features               = 'SQLENGINE'#,DQ,DQC
            SQLCollation           = 'SQL_Latin1_General_CP1_CI_AS'
            InstallSharedDir       = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir    = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir            = 'E:\'
            InstallSQLDataDir      = 'E:\MSSQL13.MSSQLSERVER\MSSQL\Data'
            SQLUserDBDir           = 'E:\MSSQL13.MSSQLSERVER\MSSQL\Data'
            SQLUserDBLogDir        = 'F:\MSSQL13.MSSQLSERVER\MSSQL\Data'
            SQLTempDBDir           = 'E:\MSSQL13.MSSQLSERVER\MSSQL\Data'
            SQLTempDBLogDir        = 'F:\MSSQL13.MSSQLSERVER\MSSQL\Data'
            SQLBackupDir           = 'E:\MSSQL13.MSSQLSERVER\MSSQL\Backup'
            SQLSourcePath          = 'C:\InstallMedia\SQL2016RTM'
            MinMemory              = 1024
            MaxMemory              = 12288
        }
    )
    SSRS = @(
        @{
            SQLInstanceExe             = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\ReportServer\bin\ReportingServicesService.exe'
            DBHostName                 = 'phitedbcl2'
            DBInstance                 = 'MSSQLSERVER'
            DBName                     = 'ReportServer'
            DBTempName                 = 'ReportServerTemp'
        }
    )
}
