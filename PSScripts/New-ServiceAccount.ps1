<#
.SYNOPSIS
Creates a service account.

.OUTPUTS
Results are output to screen.

.PARAMETER name
Specifies the name of the account to create.
.PARAMETER ServiceAccount
Creates a normal service account with a generated password. 
.PARAMETER ManagedServiceAccount
Creates a managed service account.
.PARAMETER groupManagedServiceAccount
Creates a group managed service account.
.PARAMETER DNSName
Required when creating a group managed service account. Can be website FQDN or system FQDN for example.
.PARAMETER AddServiceAccountPasswordToPasswordState
Creates a managed service account.
.PARAMETER PasswordStateListID
Input the PasswordState Password List ID number.
.PARAMETER PasswordStateListApiKey
Input the PasswordState Password List API key. 
.PARAMETER UnixID
Switch to determine whether to add unix attributes to the service account. This will only work for Server Accounts. Not group managed or regular managed service accounts. 
.EXAMPLE 
.\New-ServiceAccount.ps1 -name SP2016-SVC -ServiceAccount -AddServiceAccountPasswordToPasswordState -PasswordStateListID XXXX -PasswordStateListApiKey apikeyhere
.EXAMPLE 
.\New-ServiceAccount.ps1 -name SP2016-SVC -GroupManagedServiceAccount -GroupManagedServiceAccountGroup "SP2016-SVCGroup" -DNSName "wsfc45.default.com"
.NOTES
Written by: Kevin Bickmore
#>

param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [string]$name,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [string]$Description,
    [switch]$ServiceAccount,
    [switch]$ManagedServiceAccount,
    [switch]$GroupManagedServiceAccount,
    [string]$DNSName,
    [switch]$AddServiceAccountPasswordToPasswordState,
    [string]$PasswordStateListID,
    [string]$PasswordStateListApiKey,
    [switch]$UnixID
)

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
function New-RandomPassword
{
    <#
    .SYNOPSIS
        Generates a random password of a desired length.
    .DESCRIPTION
        See synopsis
    .PARAMETER Length
        Controls the length of the password generated
    .EXAMPLE
        New-RandomPassword -Length 25
    .NOTES
        Author  : Kevin Bickmore
        Thanks be to some heyscriptingguy post that I can't find which helped me write this.
    .LINK
        No link
    #>
    param(
        [int]$Length = 19
    )
    $punc = 40..46
    $digits = 48..57
    $letters = 65..90 + 97..122

    $password = Get-Random -count $Length `
            -input ($punc + $digits + $letters) |
                    % -begin { $aa = $null } `
                    -process {$aa += [char]$_} `
                    -end {$aa}

    return $password  
}

function Add-PasswordStatePassword
{
    param(
    [parameter(Mandatory=$True)]
    [ValidateLength(32,32)]
    [string]$APIKey,
    [parameter(Mandatory=$True)]
    [int]$PasswordListID,
    [parameter(Mandatory=$True)]
    $Title,
    [parameter(Mandatory=$True)]
    $Password,
    [parameter(Mandatory=$True)]
    [string]$Username
    )

    $URI = "https://PasswordState.$($Domain.DNSRoot)/api/passwords/`?format=xml"            
        $Body = @{
        "PasswordListID"="$PasswordListID"
        "Title"="$Title"
        "UserName"="$UserName"
        "apikey"="$APIKey"
        "Password"="$Password"
        }
        $Response = Invoke-WebRequest -UseBasicParsing -Uri $URI -Body $Body -Method Post

        $Output = @{
                    PasswordListID = $PasswordListID
                    Title = $Title
                    Status = "Created"
                    Password = $Password
                   } 
        $Output
}#End function Add-PasswordStatePassword

$Description = "$($Description)"

if ($ServiceAccount)
{
    try 
    {
        $Account = Get-ADUser $name
        if ($Account)
        {
            Write-Output "The account name exists. Stopping."
            break
        }
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
        Write-Output "The account does not exist, continuing."
    }
}

if ($GroupManagedServiceAccount -or $ManagedServiceAccount)
{
    try 
    {
        $ExistingADServiceAccount = Get-ADServiceAccount $name -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if ($ExistingADServiceAccount) 
        {
            Write-Output "The managed service account $($ExistingADServiceAccount.samAccountName) exists. Stopping."
            break
        }
    }
    catch 
    { 
    }
}

if ($ServiceAccount)
{
    [string]$UnsecurePassword = New-RandomPassword -Length 25
    $SecurePassword = ConvertTo-SecureString $UnsecurePassword -AsPlainText -Force 
    [string]$PasswordStatePassword = $UnsecurePassword

    try 
    {
        New-ADUser -Name $name -Description $Description -DisplayName $name -SamAccountName $name -AccountPassword $SecurePassword -UserPrincipalName "$($name)@$($Domain.DNSRoot)" -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true -CannotChangePassword $true -Verbose
        $ServiceAccountCreated = $true
    }
    catch [Microsoft.ActiveDirectory.Management.ADPasswordComplexityException]
    {
        Remove-ADObject -Identity $name
        Write-Output "Password was not complex enough. Try again."
        break
    }
    catch
    {
        Write-Output "Creating service account $($name) failed."
        Write-Output "$($Error[0])"
        break
    }
    if ($ServiceAccountCreated)
    {
        do {
            Start-Sleep -Seconds 2
            Write-Output "."
            try 
            {
                $SAConfirmed = Get-ADUser -Identity $name
            }
            catch
            {   
            }
        } while (!($SAConfirmed))
        Add-ADGroupMember -Identity 'Service Accounts' -Members $name
    }
    if ($UnixID)
    {
        if ($SAConfirmed)
        {
            Set-UserAcctUid -UserAccount $SAConfirmed.SamAccountName
        }
    }
    if ($AddServiceAccountPasswordToPasswordState)
    {
        try 
        {
            Add-PasswordStatePassword -APIKey $PasswordStateListApiKey -PasswordListID $PasswordStateListID -Title $name -Password $PasswordStatePassword -Username $name
        }
        catch 
        {
            Write-Output "Couldn't add account and password to PasswordState. Try again."
            Write-Output "Password is: $($UnsecurePassword)"
            Write-Output "Add account and password to PasswordState manually."
            Write-Output "$($Error[0])"
            break
        }
    }
    if (!($AddServiceAccountPasswordToPasswordState))
    {
        Write-Output "$($UnsecurePassword)"
    }
}

if ($ManagedServiceAccount)
{
    try
    {
        Get-ADServiceAccount -Identity $name -ErrorAction SilentlyContinue
    }
    catch
    {
        Write-Output "MSA doesn't already exist. Creating $($name)."
    }
    try 
    {
        New-ADServiceAccount -Name $name -SamAccountName $name -DisplayName $name -Description $Description -Enabled $true -RestrictToSingleComputer
        Write-Output "$($name) created."
        $MSACreated = $true
    }
    catch 
    {
        Write-Output "Couldn't create MSA $($name)."
        Write-Output "$($Error[0])"
        break
    }
    if ($MSACreated)
    {
        do {
            Start-Sleep -Seconds 2
            Write-Output "."
            try 
            {
                $MSAConfirmed = Get-ADServiceAccount -Identity $name
            }
            catch
            {   
            }
        } while (!($MSAConfirmed))
        Add-ADGroupMember -Identity 'Service Accounts' -Members $MSAConfirmed
    }
}

if ($GroupManagedServiceAccount)
{
    $GroupManagedServiceAccountGroup = "$($Name)_Group"
    try 
    {
        Get-ADGroup $GroupManagedServiceAccountGroup -ErrorAction SilentlyContinue
    }
    catch 
    {
        Write-Output "Group for this environment does not exist. Creating group $GroupManagedServiceAccountGroup."
        $GroupManagedServiceAccountGroupSam = $GroupManagedServiceAccountGroup.Replace(" ","")
        New-ADGroup -Description ("Group that grants access to " + $name + " group managed service account.") -DisplayName $GroupManagedServiceAccountGroupSam -SamAccountName $GroupManagedServiceAccountGroupSam -Name $GroupManagedServiceAccountGroupSam -GroupCategory Security -GroupScope DomainLocal
    }
    
    do {
        Start-Sleep -Seconds 2
        Write-Output "."
        try 
        {
            $gMSAGroup = Get-ADGroup $GroupManagedServiceAccountGroup -ErrorAction SilentlyContinue
            Write-Output "$($gMSAGroup.samAccountName) found."
        }
        catch 
        {

        }
    } while (!($gMSAGroup))

    try
    {
        Get-ADServiceAccount -Identity $name -ErrorAction SilentlyContinue
    }
    catch
    {
        Write-Output "gMSA doesn't already exist. Creating $($name)."
    }
    try 
    {
        New-ADServiceAccount -Name $name -SamAccountName $name -DisplayName $name -Description $Description -Enabled $true -PrincipalsAllowedToRetrieveManagedPassword $gMSAGroup -DNSHostName $DNSName
        Write-Output "$($name) created."
        $gMSACreated = $true
    }
    catch 
    {
        Write-Output "Couldn't create gMSA $($name)."
        Write-Output "$($Error[0])"
        break
    }
    if ($gMSACreated)
    {
        do {
            Start-Sleep -Seconds 2
            Write-Output "."
            try 
            {
                $gMSAConfirmed = Get-ADServiceAccount -Identity $name
            }
            catch
            {   
            }
        } while (!($gMSAConfirmed))
        Add-ADGroupMember -Identity 'Service Accounts' -Members $gMSAConfirmed
    }
}