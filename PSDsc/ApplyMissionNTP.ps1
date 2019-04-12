param (
    [string]$NodeName
)
Configuration NTPMission
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Node $NodeName
    {
        Registry ntpservers
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters'
            ValueName = "NtpServer"
            ValueData = "ntp.domain.corp,0x01"
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
    }
}
$StartingLocation = Get-Location
Push-Location \\path\to\dsc\runpath
NTPMission
Start-DscConfiguration -Path .\NTPMission -ComputerName $NodeName -Force -Wait
Push-Location $StartingLocation 