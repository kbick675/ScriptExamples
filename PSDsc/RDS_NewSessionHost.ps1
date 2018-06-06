param(
    [string]$NodeName
)

Configuration RemoteDesktopSessionHost 
{ 
    param(
        [string]$NodeName
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    
    Node $NodeName
    { 
        LocalConfigurationManager 
        { 
            RebootNodeIfNeeded = $true 
        }
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
        Registry EnableRDP
        {
            Ensure = "Present"
            Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
            ValueName = "fDenyTSConnections"
            ValueData = "0"
            ValueType = "Dword"
        }
        Registry EnableRDPNLA
        {
            Ensure = "Present"
            Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
            ValueName = "UserAuthentication"
            ValueData = "1"
            ValueType = "Dword"
        }
        Registry ServerList
        {
            Ensure = "Present"
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
            ValueName = "LicenseServers"
            ValueData = "vm-ist-rdgw1.domain.corp"
            ValueType = "String"
            DependsOn = "[WindowsFeature]RDS-RD-Server"
        }
        Registry TSLicensingMode
        {
            Ensure = "Present"
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
            ValueName = "LicensingMode"
            ValueData = "4"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]RDS-RD-Server"
        }
        Registry RCMLicenseMode
        {
            Ensure = "Present"
            Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\Licensing Core"
            ValueName = "LicensingMode"
            ValueData = "4"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]RDS-RD-Server"
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
            DependsOn = '[Registry]RCMLicenseMode'
        }  
    }
} 
$StartingLocation = Get-Location

Push-Location \\path\to\dsc\runpath

RemoteDesktopSessionHost -NodeName $NodeName -OutputPath .\RDSDSC\ 

Set-DscLocalConfigurationManager -ComputerName $NodeName -verbose -path .\RDSDSC\ 

Start-DscConfiguration -ComputerName $NodeName -verbose -path .\RDSDSC\

Push-Location $StartingLocation