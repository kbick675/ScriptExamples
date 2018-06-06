param(
    [string]$Name
)

$ADObject = Get-ADObject -filter {(Name -like $Name) -or (SamAccountName -like $Name)}
$Domain = Get-ADDomain
function Set-UserAcctUid
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$UserAccount = $UserAccount
    )

    $Account = Get-ADUser -Identity $UserAccount -Properties *
    if (!($Account.uidnumber))
    {
        $NIS = Get-ADObject "CN=$($Domain.Name),CN=ypservers,CN=ypServ30,CN=RpcServices,CN=System,$($Domain.DistinguishedName)" -Properties:*
        $maxUID = $NIS.msSFU30MaxUidNumber 
        Write-Output "Uid number will be set to $($maxUID) for $($Account.Name)."
        Set-ADUser -Identity $Account.SamAccountName -Replace @{msSFU30Name = $Account.SamAccountName} -Verbose
        Set-ADUser -Identity $Account.SamAccountName -Replace @{mssfu30nisdomain = "$($Domain.Name)"} -Verbose
        Set-ADUser -Identity $Account.SamAccountName -Replace @{uid = $AdminAccount.SamAccountName} -Verbose
        Set-ADUser -Identity $Account.SamAccountName -Replace @{gidnumber="1000003"} -Verbose
        Set-ADUser -Identity $Account.SamAccountName -Replace @{uidnumber=$maxUID} -Verbose
        Set-ADObject $NIS -Replace @{msSFU30MaxUidNumber = "$($NIS.msSFU30MaxUidNumber + 1)"} -Verbose
    }
    elseif ($Account.uidnumber)
    {
        Write-Output "$($Account.Name) already has a uid number."
    }
}

function Set-GroupAcctGid
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
    [string]$GroupName = $GroupName
    )
    $Group = Get-ADGroup -Identity $GroupName -Properties *
    if ($Group.gidNumber -eq $null)
    {
        $NIS = Get-ADObject "CN=$($Domain.Name),CN=ypservers,CN=ypServ30,CN=RpcServices,CN=System,$($Domain.DistinguishedName)" -Properties:*
        $maxGID = $NIS.msSFU30MaxgidNumber 
        Write-Output "Gid number will be set to $($maxGID) for $($Group.Name)."
        Set-ADGroup -Identity $Group.SamAccountName -Replace @{msSFU30Name = $Account.SamAccountName} -Verbose
        Set-ADGroup -Identity $Group.SamAccountName -Replace @{mssfu30nisdomain = "$($Domain.Name)"} -Verbose
        Set-ADGroup -Identity $Group.SamAccountName -Replace @{gidnumber=$maxGID} -Verbose
        Set-ADObject $NIS -Replace @{msSFU30MaxGidNumber = "$($NIS.msSFU30MaxGidNumber + 1)"} -Verbose
    }
    elseif ($Group.gidnumber -ne $null)
    {
        Write-Output "$($Group.Name) already has a gid number."
    }
}

if ($ADObject)
{
    if ($ADObject.ObjectClass -eq 'user')
    {
        Set-UserAcctUid -UserAccount $ADObject.ObjectGUID
    }
    if ($ADObject.ObjectClass -eq 'group')
    {
        Set-GroupAcctGid -GroupName $ADObject.ObjectGUID
    }
}
elseif (!($ADObject))
{
    Write-Output "No AD Object exists with name $($Name)."
}
