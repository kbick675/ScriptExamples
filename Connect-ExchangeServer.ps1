<#
.SYNOPSIS
    Connects to a target exchange server
.DESCRIPTION
    See synopsis
.PARAMETER ServerName
    Provides the server to run against
.EXAMPLE
    Connect-ExchangeServer -ServerName ht-dc-ex-d1-n1
.NOTES
    Author  : Kevin Bickmore
.LINK
    No link
#>
param(
    [string]$ServerName
)

$Domain = Get-ADDomain
function getServerName
{
    try 
    {
        $ADDomain = $ADDC.DefaultPartition
        $config = Get-Childitem "AD:\CN=Microsoft Exchange,CN=Services,CN=Configuration,$($ADDomain)"
        $OrgName = $config | where {$_.ObjectClass -eq 'msExchOrganizationContainer'}
        $ServerNames = (Get-ChildItem "AD:\CN=Servers,CN=Exchange Administrative Group (FYDIBOHF23SPDLT),CN=Administrative Groups,$($OrgName.DistinguishedName)").Name    
    }
    catch [System.Management.Automation.ItemNotFoundException]
    {
        Write-Output "Your account may be unable to enumerate the Exchange organizational configuration."
        Write-Output "Please try again with a different account or contact your Exchange administrators."
        Write-Output "Error: $($Error[0].Exception)"
    }
    catch
    {
        Write-Output "$($Error[0].Exception)"
    }
    if ($ServerNames)
    {
        $Connection = "Down"
        do 
        {
            $ServerName = Get-Random -InputObject $ServerNames
            if (Test-WSMan -ComputerName $ServerName)
            {
                $Connection = "Up"
            }
        } while ($Connection -eq "Down")
        
    }
    return $ServerName
}

$OpenExchangeSession = Get-PSSession | where ConfigurationName -EQ "Microsoft.Exchange"

if ($OpenExchangeSession)
{
    Write-Output "PSSession with Configuration Microsoft.Exchange is already created."
    Write-Output "Session Id is: $($OpenExchangeSession.Id)"
    Write-Output "Session Computer Name is: $($OpenExchangeSession.ComputerName)"
    Write-Output "Stoppping..."
    break
}
$Attempt = 0
do {
    if ($ServerName)
    {
        if (!(Test-WSMan -ComputerName $ServerName))
        {
            Write-Output "$($ServerName) is not online. Picking new server..."
            $ServerName = getServerName
        }
    }
    elseif (!($ServerName))
    {
        $ServerName = getServerName
    }
    try 
    {
        Write-Output "Connecting to $($ServerName)..."
        $ExchSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$($ServerName).$($Domain.DNSRoot)/powershell -Authentication Kerberos
        Import-PSSession -Session $ExchSession -Verbose -AllowClobber
    }
    catch 
    {
        Write-Output "Connection to $($ServerName) failed..."
    }
    $ServerName = $null
    $Attempt++
    Start-Sleep -Seconds 1
    Write-Output "."
} while ((!($ExchSession)) -or $Attempt -ge 10)