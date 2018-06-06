param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [String]$SamAccountName,
    [switch]$Enable,
    [switch]$Disable,
    [Parameter(ParameterSetName = "SecurityDisable")]
    [switch]$SecurityDisable,
    [Parameter(ParameterSetName = "SecurityDisable")]
    [string]$Reason,
    [switch]$UnusedDisable
)
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

$ServiceAccount = Get-ADUser -Identity $SamAccountName -Properties Name,Description,samAccountName,extensionAttribute15,LastLogon -ErrorAction SilentlyContinue
if(!($ServiceAccount))
{
    Write-Output "Account does not exist - $($SamAccountName)."
}
if ($ServiceAccount)
{
    if ($Disable)
    {
        $ADUser = $ServiceAccount
        if ($ADUser.Enabled -eq $true)
        {  
            Write-Output "Disabling $($ADUser.Name)."
            try
            {
                Disable-ADAccount -Identity $ADUser.samAccountName -Verbose
                Write-Output "$($ADUser.Name) disabled."
            }
            catch
            {
                Write-Output "$($Error[0])"
                Write-Output "$($Error[0].CategoryInfo)"
                Write-Output "$($Error[0].FullyQualifiedErrorId)"
                Write-Output "Unable to disable $($ADUser)."
            }
        }
        elseif ($ADUser.Enabled -eq $false)
        {
            Write-Output "$($ADUser.Name) already disabled."
        }
    }
    if ($SecurityDisable -or $UnusedDisable)
    {
        $ADUser = $ServiceAccount

        if ($ADUser.Enabled -eq $true)
        {
            if ($UnusedDisable)
            {
                $ninetydays = (Get-Date).AddDays(-90)
                $time = $ADUser.LastLogon
                $LastLogonTime = [DateTime]::FromFileTime($time)
                if ($LastLogonTime -le $ninetydays)
                {
                    Write-Output "$($ADUser.Name) last logged on 90 or more days ago at $($LastLogonTime)."
                    Write-Output "Disabling $($ADUser.Name)."
                    try
                    {
                        Disable-ADAccount -Identity $ADUser.samAccountName -Verbose
                        Write-Output "$($ADUser.Name) disabled."
                        $Disabled = $true
                    }
                    catch
                    {
                        Write-Output "$($Error[0])"
                        Write-Output "$($Error[0].CategoryInfo)"
                        Write-Output "$($Error[0].FullyQualifiedErrorId)"
                        Write-Output "Unable to disable $($ADUser)."
                    }
                }
                elseif ($LastLogonTime -gt $ninetydays)
                {
                    Write-Output "$($ADUser.Name) last logged on less than 90 days ago at $($LastLogonTime) so it will not be disabled."
                }
            }
            if ($SecurityDisable)
            {
                try
                {
                    Disable-ADAccount -Identity $ADUser.samAccountName -Verbose
                    Write-Output "$($ADUser.Name) disabled."
                    $Disabled = $true
                }
                catch
                {
                    Write-Output "$($Error[0])"
                    Write-Output "$($Error[0].CategoryInfo)"
                    Write-Output "$($Error[0].FullyQualifiedErrorId)"
                    Write-Output "Unable to disable $($ADUser)."
                }
            }
            if ($Disabled)
            {
                if ($SecurityDisable)
                {
                    try
                    {
                        Set-ADUser -Identity $ADUser.samAccountName -Replace @{extensionAttribute15='SecurityDisable'}
                        Set-ADUser -Identity $ADUser.samAccountName -Description "$($ADUser.Description) | Disabled Reason: $($Reason)"
                        Write-Output "$($ADUser.Name) security disable attribute set."
                    }
                    catch
                    {
                        Write-Output "$($Error[0])"
                        Write-Output "$($Error[0].CategoryInfo)"
                        Write-Output "$($Error[0].FullyQualifiedErrorId)"
                        Write-Output "Unable to set disable attribute for $($ADUser)."
                    }
                    try 
                    {
                        [string]$UnsecurePassword = New-RandomPassword -Length 31
                        $SecurePassword = ConvertTo-SecureString $UnsecurePassword -AsPlainText -Force 
                        Set-ADAccountPassword -Identity $ADUser.samAccountName -NewPassword $SecurePassword -Reset
                        Write-Output "Password for $($ADUser.Name) has been changed."
                    }   
                    catch 
                    {
                        Write-Output "$($Error[0])"
                        Write-Output "$($Error[0].CategoryInfo)"
                        Write-Output "$($Error[0].FullyQualifiedErrorId)"
                    }
                    try 
                    {
                        Set-ADUser -Identity $ADUser.samAccountName -ChangePasswordAtLogon $true
                        Write-Output "Account now requires that the password be changed at logon."
                    }
                    catch 
                    {
                        Write-Output "$($Error[0])"
                        Write-Output "$($Error[0].CategoryInfo)"
                        Write-Output "$($Error[0].FullyQualifiedErrorId)"
                    }
                }
                if ($UnusedDisable)
                {
                    try
                    {
                        Set-ADUser -Identity $ADUser.samAccountName -Replace @{extensionAttribute15='UnusedDisable'}
                        Write-Output "$($ADUser.Name) unused disable attribute set."
                    }
                    catch
                    {
                        Write-Output "$($Error[0])"
                        Write-Output "$($Error[0].CategoryInfo)"
                        Write-Output "$($Error[0].FullyQualifiedErrorId)"
                        Write-Output "Unable to set disable attribute for $($ADUser)."
                    }
                }
            }
        }
        elseif ($ADUser.Enabled -eq $false)
        {
            Write-Output "$($ADUser.Name) already disabled."
        }
    }
    if ($Enable)
    {
        $ADUser = $SamAccountName
        if ($ADUser.Enabled -eq $false)
        {
            if ($ADUser.extensionAttribute15 -eq 'SecurityDisable')
            {
                Write-Output "$($ADUser.Name) was disabled for security reasons. Please check with Infosec before enabling this account."
                Write-Output "A Reason may have been specified in the Description:"
                Write-Output "$($ADUser.Description)"
            }
            if ($ADUser.extensionAttribute15 -eq 'UnusedDisable')
            {
                Write-Output "$($ADUser.Name) was disabled because it had not been used within at least 90 days at the time."
                Write-Output "Enabling $($ADUser.Name)."
                try
                {
                    Enable-ADAccount -Identity $ADUser.samAccountName  
                }
                catch
                {
                    Write-Output "$($Error[0])"
                    Write-Output "$($Error[0].CategoryInfo)"
                    Write-Output "$($Error[0].FullyQualifiedErrorId)"
                    Write-Output "Unable to enable $($ADUser)."
                }
                finally 
                {
                    if ((Get-ADUser -Identity $ADUser.samAccountName).Enabled -eq $true)
                    {
                        Write-Output "$($ADUser.Name) enabled."
                    }
                }
            }
        }
        elseif ($ADUser.Enabled -eq $true)
        {
            Write-Output "$($ADUser.Name) already enabled."
        }
    }
}