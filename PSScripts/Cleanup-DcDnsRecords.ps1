param (
    [Parameter(Mandatory=$true)]
    [string]
    $DCName
)

$dnsZone = "$($ENV:USERDNSDOMAIN)"
$activeDc = "$($Env:LOGONSERVER.TrimStart("\\")).$($dnsZone)"
$dcIp = Get-DnsServerResourceRecord -Name $DCName -ComputerName $activeDc -ZoneName $dnsZone
$dcRecords = Get-DnsServerResourceRecord -ZoneName "_msdcs.$($dnsZone)" -ComputerName $activeDc | Where-Object {$_.RecordData.IPv4Address -eq $dcIp -or $_.RecordData.NameServer -eq “$($DCName).$($dnsZone).” -or $_.RecordData.DomainName -eq “$($DCName).$($dnsZone).”}
$dcRecords

$answer = Read-Host -Prompt "Cleanup the above DNS records related to: $($DCName)? (Y)es/(N)o"
switch -wildcard ($answer) {
    "Y*" { 
        Write-Output "Cleaning DNS records for $($DCName)..."
        $dcRecords | Remove-DnsServerResourceRecord -ZoneName "_msdcs.$($dnsZone)" -Force
    }
    "N*" {
        Write-Output "Stopping..."
    }
    Default {}
}