param(
    [Parameter(Mandatory=$true)]
    [string]$GroupName,
    [Parameter(Mandatory=$true)]
    [string]$Description,
    [switch]$UnixID,
    [string]$TargetOU
    )

$Domain = Get-ADDomain
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

$GroupNameAD = Get-ADGroup -Identity $GroupName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
if (!($GroupNameAD))
{
    Write-Output "$($GroupName) does not exist, continuing."
}
elseif ($GroupNameAD)
{
    Write-Output "$($GroupName) does exist, stopping."
    break
}
if ($TargetOU)
{
    try
    {
        Get-ADOrganizationalUnit $TargetOU
    }
    catch
    {
        Write-Output "$($TargetOU) not found."
        $OUFound = $false
    }
    if ($OUFound )
    {
        try
        { 
            New-ADGroup -Name $GroupName -GroupCategory Security -GroupScope DomainLocal -Path $TargetOU -Description $Description -Verbose
            Write-Output "$($GroupName) created."
        }
        catch 
        {
            Write-Output "$($Error[0])"
            Write-Output "$($Error[0].CategoryInfo)"
            Write-Output "$($Error[0].FullyQualifiedErrorId)"
            Write-Output "Could not create $($GroupName)."
        }
    }
    if ($OUFound -eq $false)
    {
        try
        { 
            New-ADGroup -Name $GroupName -GroupCategory Security -GroupScope DomainLocal -Description $Description -Verbose
            Write-Output "$($GroupName) created."
        }
        catch 
        {
            Write-Output "$($Error[0])"
            Write-Output "$($Error[0].CategoryInfo)"
            Write-Output "$($Error[0].FullyQualifiedErrorId)"
            Write-Output "Could not create $($GroupName)."
        }
    }
}
try
{ 
    New-ADGroup -Name $GroupName -GroupCategory Security -GroupScope DomainLocal -Path $TargetOU -Description $Description -Verbose
    Write-Output "$($GroupName) created."
}
catch 
{
    Write-Output "$($Error[0])"
    Write-Output "$($Error[0].CategoryInfo)"
    Write-Output "$($Error[0].FullyQualifiedErrorId)"
    Write-Output "Could not create $($GroupName)."
}

if ($UnixID)
{
    $Group = Get-ADGroup -Identity $GroupName -Properties *
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