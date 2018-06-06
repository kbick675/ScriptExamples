param(
    [switch]$Expired,
    [switch]$Invalid,
    [switch]$2012,
    [switch]$2008,
    [string]$ManagementServer="vm-sc-om1.domain.corp"
    )

#Import SCOM 2016+ PowerShell Module
if (!(Get-Command Get-SCOMAgent -ErrorAction SilentlyContinue))
{
    Import-Module "C:\Program Files\Microsoft System Center\Operations Manager\Powershell\OperationsManager\OperationsManager.psm1"
}
#Connect to OpsMgr Management Group
New-SCOMManagementGroupConnection -ComputerName $ManagementServer

$scriptblockforexpiredcerts2012 =
{
    $thumbprint = $args[0]
    Write-Host $args[1]
    Write-Host "Checking for expired cert with thumbprint: $thumbprint"
    Write-Host "-----"
    Get-ChildItem -Path Cert:\LocalMachine\My\$thumbprint | fl 
    Get-ChildItem -Path Cert:\LocalMachine\My\$thumbprint | Remove-ChildItem
    Write-Host "-----"
    Write-Host ""
} 
$scriptblockforexpiredcerts2008 = 
{
    function Remove-Certs2008 
    {
        param(
            [string]$thumbprint
            )

        $store = New-Object System.Security.Cryptography.x509Certificates.x509Store("My","LocalMachine")
        $store.Open("ReadWrite")
        # Need some criteria here to filter the list of certificates appropriately
        $certs = $store.Certificates | Where-Object {$_.Thumbprint -eq $thumbprint}
        $certs
        ForEach ($cert in $certs)
        {
            $store.Remove($cert)
        }
        $store.Close()
    }
    Remove-Certs2008 -thumbprint $arge[0] 
}
#### 2012 Servers
if (($Expired -eq $true) -and ($2012 -eq $true)) 
{
    $expirecertsgroup = get-scomgroup -DisplayName "Expired Certificates Group"
    $expirecertsgroupmember = $expirecertsgroup.GetRelatedMonitoringObjects()

    foreach ($member in $expirecertsgroupmember)
    {
        $alertobject = Get-SCOMMonitoringObject -Id $member.Id
        $alertobject.DisplayName
        $alertobject.Name
        $thumbprint = $alertobject.Name
        ($alertobject.'[SystemCenterCentral.Utilities.Certificates.Certificate].CertIssuedBy').Value
        $targetcomputer = ($alertobject.'[Microsoft.Windows.Computer].PrincipalName').Value
        if (Test-Connection $targetcomputer -Count 1)
        {
            Invoke-Command -ComputerName $targetcomputer -ScriptBlock $scriptblockforexpiredcerts2012 -args $thumbprint,$targetcomputer -ErrorAction SilentlyContinue
        }
    }
}
if (($Invalid -eq $true) -and ($2012 -eq $true)) 
{
    $invalidcertsgroup = get-scomgroup -DisplayName "Invalid Certificates Group"
    $invalidcertsgroupmember = $invalidcertsgroup.GetRelatedMonitoringObjects()

    foreach ($member in $invalidcertsgroupmember)
    {
        $alertobject = Get-SCOMMonitoringObject -Id $member.Id
        $alertobject.DisplayName
        $alertobject.Name
        $thumbprint = $alertobject.Name
        ($alertobject.'[SystemCenterCentral.Utilities.Certificates.Certificate].CertIssuedBy').Value
        $targetcomputer = ($alertobject.'[Microsoft.Windows.Computer].PrincipalName').Value
        if (Test-Connection $targetcomputer -Count 1)
        {
        Invoke-Command -ComputerName $targetcomputer -ScriptBlock $scriptblockforexpiredcerts2012 -args $thumbprint,$targetcomputer -ErrorAction SilentlyContinue
        }
    }
}

#### 2008 Servers
if (($Expired -eq $true) -and ($2008 -eq $true)) 
{
    $expirecertsgroup = get-scomgroup -DisplayName "Expired Certificates Group"
    $expirecertsgroupmember = $expirecertsgroup.GetRelatedMonitoringObjects()

    foreach ($member in $expirecertsgroupmember)
    {
        $alertobject = Get-SCOMMonitoringObject -Id $member.Id
        $alertobject.DisplayName
        $alertobject.Name
        $thumbprint = $alertobject.Name
        ($alertobject.'[SystemCenterCentral.Utilities.Certificates.Certificate].CertIssuedBy').Value
        $targetcomputer = ($alertobject.'[Microsoft.Windows.Computer].PrincipalName').Value
        if (Test-Connection $targetcomputer -Count 1)
        {
            Invoke-Command -ComputerName $targetcomputer -ScriptBlock $scriptblockforexpiredcerts2008 -ArgumentList $thumbprint
        }
    }
}
if (($Invalid -eq $true) -and ($2008 -eq $true)) 
{
    $invalidcertsgroup = get-scomgroup -DisplayName "Invalid Certificates Group"
    $invalidcertsgroupmember = $invalidcertsgroup.GetRelatedMonitoringObjects()

    foreach ($member in $invalidcertsgroupmember)
    {
        $alertobject = Get-SCOMMonitoringObject -Id $member.Id
        $alertobject.DisplayName
        $alertobject.Name
        $thumbprint = $alertobject.Name
        ($alertobject.'[SystemCenterCentral.Utilities.Certificates.Certificate].CertIssuedBy').Value
        $targetcomputer = ($alertobject.'[Microsoft.Windows.Computer].PrincipalName').Value
        if (Test-Connection $targetcomputer -Count 1)
        {
            Invoke-Command -ComputerName $targetcomputer -ScriptBlock $scriptblockforexpiredcerts2008 -ArgumentList $thumbprint
        }
    }
}