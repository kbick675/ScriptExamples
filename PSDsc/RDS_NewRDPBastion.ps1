param(
    [string]$NodeName
)
Configuration LCM
{
    param(
        [Parameter(mandatory=$true)]
        [string[]]$NodeName
        )

    Node $NodeName
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration'
            CertificateID = $Node.Thumbprint
        }
    }
}
Configuration NewRDPBastion 
{ 
    param(
        [string]$NodeName,
        [pscredential]$DomainAdmin
    )

    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion 2.8.0.0 

    Node $NodeName
    {
        WindowsFeature Remote-Desktop-Services 
        { 
            Ensure = "Present" 
            Name = "Remote-Desktop-Services" 
        }
        WindowsFeature RDS-RD-Server 
        { 
            Ensure = "Present" 
            Name = "RDS-RD-Server" 
        }
        WindowsFeature RSAT-RDS-Tools 
        { 
            Ensure = "Present" 
            Name = "RSAT-RDS-Tools" 
            IncludeAllSubFeature = $true 
        }
        MsiPackage rdcman
        {
            Ensure = "Present"
            Path = "\\filer1\local\Public\Installers\Microsoft\rdcman\rdcman.msi"
            Arguments = "/qn"
            ProductId = "0240359E-6A4C-4884-9E94-B397A02D893C"
        }
        MsiPackage TortoiseSVN
        {
            Ensure = "Present"
            Path = "\\filer1\local\Public\Installers\SVN\SCCM\1.9.7\64-bit\TortoiseSVN-1.9.7.27907-x64-svn-1.9.7.msi"
            Arguments = "ADDLOCAL=ALL /QN"
            ProductId = "FBD345DC-093A-4D89-A9B8-10C1BA356048"
        }
        Group RemoteDesktopUsers
        {
            GroupName = 'Remote Desktop Users'
            Ensure = 'Present'
            MembersToInclude = @("domain\Users")
            Credential = $DomainAdmin
        }
        Group Administrators
        {
            GroupName = 'Administrators'
            Ensure = 'Present'
            MembersToInclude = @("domain\Admins")
            Credential = $DomainAdmin
        }
        Registry EnableRDP
        {
            Ensure = "Present"
            Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
            ValueName = "fDenyTSConnections"
            ValueData = "0"
            ValueType = "Dword"
            Force = $true
        }
        Registry EnableRDPNLA
        {
            Ensure = "Present"
            Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
            ValueName = "UserAuthentication"
            ValueData = "1"
            ValueType = "Dword"
            Force = $true
        }
        Registry ServerList
        {
            Ensure = "Present"
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
            ValueName = "LicenseServers"
            ValueData = "vm-ist-rdgw1.domain.corp"
            ValueType = "String"
            DependsOn = "[WindowsFeature]RDS-RD-Server"
            Force = $true
        }
        Registry TSLicensingMode
        {
            Ensure = "Present"
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
            ValueName = "LicensingMode"
            ValueData = "4"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]RDS-RD-Server"
            Force = $true
        }
        Registry RCMLicenseMode
        {
            Ensure = "Present"
            Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\Licensing Core"
            ValueName = "LicensingMode"
            ValueData = "4"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]RDS-RD-Server"
            Force = $true
        }
        Registry ntpservers
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
            ValueName = "NtpServer"
            ValueData = "ntp3.domain.corp,0x01 ntp.domain.corp,0x01"
            ValueType = "String"
            Force = $true
        }
        Registry ntpClientType
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
            ValueName = "Type"
            ValueData = "NTP"
            ValueType = "String"
            Force = $true
        }
        Registry ntpSpecialPollInterval
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient"
            ValueName = "SpecialPollInterval"
            ValueData = "60"
            ValueType = "Dword"
            Force = $true
        }
        Registry ntpEventLogFlags
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Config"
            ValueName = "EventLogFlags"
            ValueData = "1"
            ValueType = "Dword"
            Force = $true
        }
        Script Reboot
        {
            TestScript = {
                return (Test-Path HKLM:\SOFTWARE\MyMainKey\RebootKey)
            }
            SetScript = {
                New-Item -Path HKLM:\SOFTWARE\MyMainKey\RebootKey -Force
                $global:DSCMachineStatus = 1 
            }
            GetScript = { return @{result = 'result'}}
            DependsOn = '[Registry]TSLicensingMode'
        }  
    }
}

$config = @{
    AllNodes = @(
        @{
            NodeName = $NodeName
            CertificateFile = "C:\pki\publickey.cer"
            Thumbprint = '698743ED8C0284F8FD34A5112704BB42DE944509'
            PSDscAllowDomainUser = $true
        }
    )
}

$scriptblock = {
    if (!((Get-ChildItem Cert:\LocalMachine\My\698743ED8C0284F8FD34A5112704BB42DE944509 -ErrorAction SilentlyContinue) -and (Get-ChildItem Cert:\LocalMachine\TrustedPublisher\698743ED8C0284F8FD34A5112704BB42DE944509 -ErrorAction SilentlyContinue)))
    {
        Write-Output "Installing DSC Cert"
        $Key = Get-Content C:\pki\key.txt
        $Password = Invoke-RestMethod -Uri "https://enigma/api/passwords/8764?format=xml" -Method Get -ContentType "application/xml" -Headers @{"apikey"="$Key"}
        $SecurePassword = convertto-securestring -AsPlainText -Force -String $Password.ArrayOfPassword.Password.Password        
        $Creds = New-Object System.Management.Automation.PSCredential ("username", $SecurePassword)
        Import-PfxCertificate -Password $Creds.Password -FilePath C:\pki\privatekey.pfx -CertStoreLocation Cert:\LocalMachine\My
        Import-PfxCertificate -Password $Creds.Password -FilePath C:\pki\privatekey.pfx -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
    }
    elseif ((Get-ChildItem Cert:\LocalMachine\My\698743ED8C0284F8FD34A5112704BB42DE944509 -ErrorAction SilentlyContinue) -and (Get-ChildItem Cert:\LocalMachine\TrustedPublisher\698743ED8C0284F8FD34A5112704BB42DE944509 -ErrorAction SilentlyContinue))
    {
        Write-Output "DSC Cert is Installed"
    }
}

$DomainAdminCreds = (Get-Credential)

if (!(Test-Path -Path \\$NodeName\c$\pki))
{
    New-Item -Path \\$NodeName\c$ -ItemType Directory -Name pki
}
Copy-Item -Path \\filer1\ist\ps\dsc\Certificates\* -Destination \\$NodeName\c$\pki

Invoke-Command -ScriptBlock $scriptblock -ComputerName $NodeName

$StartingLocation = Get-Location

Push-Location \\path\to\dsc\runpath

SPX_LCM -NodeName $NodeName -OutputPath .\SPX_LCM -ConfigurationData $config

Set-DscLocalConfigurationManager -ComputerName $NodeName -Path .\SPX_LCM -Verbose -Force

NewRDPBastion -NodeName $NodeName -DomainAdmin $DomainAdminCreds -Configuration $config

Start-DscConfiguration -ComputerName $NodeName -verbose -path .\NewRDPBastion -Force

Push-Location $StartingLocation