param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [string]$DistributionGroupName,
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [ValidateSet('Distribution','Security')]
    [string]$Type,
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [string]$Description,
    [string]$InputApiKey
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
function Connect-ToExchangeAsSvc
{
    <#
    This Function relies on the api for passwordstate:
    https://www.clickstudios.com.au
    #>
    param(
        [string]$ApiKey
    )

    $ServerName = getServerName
    $OpenExchangeSessions = Get-PSSession | Where-Object {($_.State -eq 'Opened')-and($_.ConfigurationName -eq 'Microsoft.Exchange')}
    if ($null -eq $OpenExchangeSessions)
    {
        Write-Output "Establishing new Exchange Session to $($ServerName)."

        $Password = Invoke-RestMethod -Uri "https://passwordstate/api/passwords/19921?format=xml" -Method Get -ContentType "application/xml" -Headers @{"apikey"="$ApiKey"}
        $SecurePassword = convertto-securestring -AsPlainText -Force -String $Password.ArrayOfPassword.Password.Password
        $SessionCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($Domain.Name)\itsportaladminsvc",$SecurePassword
        
        $Global:ExchSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$($ServerName).$(Domain.DNSRoot)/powershell -WarningAction SilentlyContinue -Credential $SessionCredential
        Import-PSSession $Global:ExchSession -AllowClobber -WarningAction SilentlyContinue | out-null
        if (Get-Module | select Name,Description | Where-Object {$_.Description -like "*$ServerName*"})
        {
            Write-Output "Exchange Session to $($ServerName) established."
        }
        else
        {
            Write-Output "Exchange Session to $($ServerName) failed."
        }
    }#End If $OpenExchangeSEssions -eq $Null
    else
    {
        Write-Output "Exchange Session already established."
    }
}#End Connect-ToExchange
function Connect-ToExchange
{
    <#
    .SYNOPSIS
        Connects to a target exchange server
    .DESCRIPTION
        See synopsis
    .PARAMETER ServerName
        Provides the server to run against
    .EXAMPLE
        Connect-ExchangeServer -ServerName dc-ex-d1-n1
    .NOTES
        Author  : Kevin Bickmore
    .LINK
        No link
    #>
    param(
        [string]$ServerName
    )

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
}
function GetDuplicateGID
{
    param (
        $GID
    )
    $DuplicateGID = Get-ADObject -Filter 'gidnumber -eq $GID'
    if ($DuplicateGID -ne $null)
    {
        do {
            $GID = $GID + 1
            $DuplicateGID = Get-ADObject -Filter 'gidnumber -eq $GID'
        } while ($DuplicateGID -ne $null)
        return $GID
    }
    if ($DuplicateGID -eq $null)
    {
        return $GID
    }
}
function SetMaxGID
{
    param(
        $NewMaxGid
    )
    if (!($NewMaxGid))
    {
        try 
        {
            $NIS = Get-ADObject "CN=$($Domain.Name),CN=ypservers,CN=ypServ30,CN=RpcServices,CN=System,$($Domain.DistinguishedName)" -Properties:*
            $NewMaxGid = $NIS.msSFU30MaxGidNumber + 1
            Set-ADObject $NIS -Replace @{msSFU30MaxGidNumber = "$($NewMaxGid)"}
            Start-Sleep -Seconds 5
            $NIS = Get-ADObject "CN=$($Domain.Name),CN=ypservers,CN=ypServ30,CN=RpcServices,CN=System,$($Domain.DistinguishedName)" -Properties:*
            if ($NIS.msSFU30MaxGidNumber -eq $NewMaxGid)
            {
                Write-Output "msSFU30MaxGidNumber has been increased by 1 to $($NIS.msSFU30MaxGidNumber)."              
            }
        }
        catch
        {
            Write-Output "Unable to increment msSFU30MaxGidNumber by 1. Please have a Domain Admin do so."
            Write-Output "$($Error[0])"
            break
        }
    }
    elseif ($NewMaxGid)
    {
        try 
        {
            $NIS = Get-ADObject "CN=$($Domain.Name),CN=ypservers,CN=ypServ30,CN=RpcServices,CN=System,$($Domain.DistinguishedName)" -Properties:*
            Set-ADObject $NIS -Replace @{msSFU30MaxGidNumber = "$($NewMaxGid)"}
            Start-Sleep -Seconds 5
            $NIS = Get-ADObject "CN=$($Domain.Name),CN=ypservers,CN=ypServ30,CN=RpcServices,CN=System,$($Domain.DistinguishedName)" -Properties:*
            if ($NIS.msSFU30MaxGidNumber -eq $NewMaxGid)
            {
                Write-Output "msSFU30MaxGidNumber has been increased by 1 to $($NIS.msSFU30MaxGidNumber)."              
            }
        }
        catch 
        {
            Write-Output "Unable to set msSFU30MaxGidNumber to $($NewMaxGid). Please have a Domain Admin do so."
            Write-Output "$($Error[0])"
            break
        }
            
    }
}
if ($InputApiKey)
{
    Connect-ToExchangeAsSvc -ApiKey $InputApiKey
}
else 
{
    Connect-ToExchange
}


if (!(Get-DistributionGroup -Identity $DistributionGroupName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue))
{
    Write-Output "$($DistributionGroupName) does not exist, continuing."
}
elseif (Get-DistributionGroup -Identity $DistributionGroupName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
{
    Write-Output "$($DistributionGroupName) does exist, stopping."
    break
}

if ($Type -eq 'Distribution')
{
    Write-Output "Attempting to create distribution group $($DistributionGroupName) of type $($Type)."
    try
    { 
        New-DistributionGroup -Name $DistributionGroupName -DisplayName $DistributionGroupName -Type "Distribution" 
        Write-Output "$($DistributionGroupName) created."
        $GroupCreated = $true
    }
    catch 
    {
        Write-Output "Could not create $($DistributionGroupName)."
        Write-Output "$($Error[0])"
    }
    if ($GroupCreated)
    {
        do 
        {
            Start-Sleep -Seconds 2
            try 
            {
                $ADGroup = Get-ADGroup -Identity $DistributionGroupName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            }
            catch 
            {
                Write-Output "."
            }
        } while (!($ADGroup))
    }
    try 
    {
        Set-ADGroup -Identity $ADGroup -Description $Description
        Write-Output "Distribution group $($ADGroup.samAccountName) description set to $($Description)."
    }
    catch
    {
        Write-Output "Could not set $($DistributionGroupName) description."
        Write-Output "$($Error[0])"
    }
}
if ($Type -eq 'Security')
{
    Write-Output "Attempting to create distribution group $($DistributionGroupName) of type $($Type)."
    try
    { 
        New-DistributionGroup -Name $DistributionGroupName -DisplayName $DistributionGroupName -Type "Security"
        Write-Output "$($DistributionGroupName) created."
        $GroupCreated = $true
    }
    catch 
    {
        Write-Output "Could not create $($DistributionGroupName)."
        Write-Output "$($Error[0])"
    }
    Start-Sleep -Seconds 15
    if ($GroupCreated)
    {
        do 
        {
            $ADGroup = Get-ADGroup -Identity $DistributionGroupName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue 
        } while (!($ADGroup))
    }
    try 
    {
            Set-ADGroup -Identity $ADGroup -Description $Description
    }
    catch
    {
        Write-Output "Could not set $($DistributionGroupName) description."
        Write-Output "$($Error[0])"
    }
    if ($UnixID)
    {
        $Group = Get-ADGroup -Identity $ADGroup.samAccountName -Properties *
        if ($Group)
        {
            try 
            {
                if ($Group.gidNumber -eq $null)
                {
                    $NIS = Get-ADObject "CN=$($Domain.Name),CN=ypservers,CN=ypServ30,CN=RpcServices,CN=System,$($Domain.DistinguishedName)" -Properties:*
                    $maxGID = GetDuplicateGID -GID $NIS.msSFU30MaxGidNumber
                    Write-Output "Gid number will be set to $($maxGID) for $($Group.Name)."
                    Set-ADGroup -Identity $Group.SamAccountName -Replace @{msSFU30Name = $Group.SamAccountName}
                    Write-Output "msSFU30Name has been set to $($Group.SamAccountName)."
                    Set-ADGroup -Identity $Group.SamAccountName -Replace @{mssfu30nisdomain = "$($Domain.Name)"}
                    Write-Output "mssfu30nisdomain has been set to $($Domain.Name)."
                    Set-ADGroup -Identity $Group.SamAccountName -Replace @{gidnumber=$maxGID}
                    Write-Output "gidnumber has been set to $($maxGID)."
                    if ($maxGID -gt ($NIS.msSFU30MaxGidNumber))
                    {
                        SetMaxGID -NewMaxGid $maxGID
                    }
                    if ($maxGID -eq ($NIS.msSFU30MaxGidNumber))
                    {
                        SetMaxGID
                    }
                }
                elseif ($Group.gidnumber -ne $null)
                {
                    Write-Output "$($Group.Name) already has a gid number."
                }    
            }
            catch
            { 
                Write-Output "Unable to set Unix GID and associated values."
                Write-Output "$($Error[0])"
                Write-Output "$($Error[0].CategoryInfo)"
                Write-Output "$($Error[0].FullyQualifiedErrorId)"
            }
        }
    }
}

Remove-PSSession $Global:ExchSession
