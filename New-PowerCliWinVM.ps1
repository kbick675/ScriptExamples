<#
.SYNOPSIS
Creates a new VM in vCenter via the PowerCli cmdlets. 

.OUTPUTS
Results are output to screen.

.PARAMETER VMName
Specifies the name of the account to create.
.PARAMETER VMTemplate
Creates the VM from the specified VM template. 
.PARAMETER VMCluster
Creates the VM in the specified cluster.
.PARAMETER VMNetwork
Sets the VM network adapter to the specified VM network.
.PARAMETER VMDatastore
Creates the VM in the specified datastore.
.PARAMETER VMOwner
Sets the Spx.AutomationX.Owner attribute.
.PARAMETER VMBusinessOwner
Sets the Spx.AutomationX.BuesinessOwner attribute.
.PARAMETER VMDescription
Sets the Spx.Description attribute.
.PARAMETER VIServer
Determines which vCenter server the commands run against. 
.PARAMETER VMDiskSize
Sets primary VM disk to 60, 80 or 100 GB. 
.PARAMETER VMvCPU
Sets the VM to the specified number of CPUs.
.PARAMETER VMMemGB
Sets the VM to the specified amount of memory in GB.
.PARAMETER GuestOS
Specifies the guest OS as 2012 or 2012.
.PARAMETER TargetOU
Places the VM account in one of the specified Organizational Units (OU).
.PARAMETER AutoUpdateGroup
Puts the VM AD Account in one of the specified security groups that determine auto update scheduling. 
.EXAMPLE
New-PowerCliVM.ps1 -VMName testkb347 -VMTemplate tpl-2016std -VMCluster Access2 -VMNetwork 'Access 2004' -VMDatastore pure1 -VMOwner kbickmore -VMBusinessOwner "ITSystems" -VMDescription "Test System"
.NOTES
Written by: Kevin Bickmore
#>

param(
    [Parameter(Mandatory=$true,Position=0)]
    [ValidateNotNull()]
    [string]$VMName,
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [ValidateSet("tpl-2012r2std","tpl-2016core","tpl-2016std","se-tpl-2016std","se-tpl-2016core")]
    [string]$VMTemplate,
    [ValidateNotNull()]
    [ValidateSet("Access","Access2")]
    [string]$VMCluster = 'Access2',
    [ValidateNotNull()]
    [ValidateSet("Access 2000","Access 2004","Access 2028","Access 2032")]
    [string]$VMNetwork = 'Access 2028',
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [ValidateSet("filer3 win1","filer4 win2","pure1")]
    [string]$VMDatastore,
    [ValidateNotNull()]
    [ValidateSet("Datacenter1","Datacenter2")]
    [string]$VMDataCenter = 'Datacenter1',
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [string]$VMOwner,
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [string]$VMBusinessOwner,
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [string]$VMDescription,
    #Use whatever your vCenter hostname is
    [string]$VIServer = "vcenter",
    [ValidateSet(60,80,100)]
    [decimal]$VMDiskSize,
    [ValidateSet(2,4,6,8)]
    [int]$VMvCPU = 2,
    [ValidateSet(2,4,6,8,12,16)]
    [int]$VMMemGB = 4,
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [string]$TargetOU,
    #If you have groups that manage auto patching
    [string]$AutoUpdateGroup
    )


$MailServerSMTPAddress = "smtp.domain.com"
$SendingAddress = "NewPowerCliVM@domain.com"

if (!(Get-Module -ListAvailable -Name VMware.PowerCLI))
{
    Write-Output "PowerCLI is not installed. Please install from Powershell Gallery: Install-Module VMware.PowerCLI"
    break
}
if ($PSVersionTable.PSEdition -eq "Core")
{
    "This version of Powershell does not support the AD Cmdlets. Any functionality that relies on them will not work."
}
if (($PSVersionTable.PSEdition -ne "Core") -or (!($PSVersionTable.PSEdition)))
{
    try 
    {
        $ComputerExists = Get-ADComputer -Identity $VMName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }
    catch 
    {
        Write-Output "Computer with name $($VMName) does not exist. Continuing..."
    }
    if ($ComputerExists)
    {
        Write-Output "Computer with name $($VMName) exists. Stopping."
        break
    } 
    elseif (!($ComputerExists))
    {
        try 
        {
            New-ADComputer -Name $VMName -SAMAccountName $VMName 
            Write-Output "Computer account created: $($VMName)."      
        }
        catch 
        {
            Write-Output "Computer account creation failed."
            Write-Output "$($Error[0])"
        }
        Start-Sleep -Seconds 5
        $NewComputer = Get-ADComputer -Identity $VMName -ErrorAction SilentlyContinue
        if ($NewComputer)
        {   
            Write-Output "Attempting move to $($TargetOU)."
            try 
            {
                Move-ADObject -Identity $NewComputer -TargetPath $TargetOU
                Write-Output "Move successful."
            }
            catch
            {
                Write-Output "Move failed."
                Write-Output "$($Error[0])"
            }
            if ($AutoUpdateGroup)
            {
                try 
                {
                    Add-ADGroupMember -Identity $AutoUpdateGroup -Members $NewComputer.SamAccountName
                    Write-Output "Added $($NewComputer.SamAccountName) to $($AutoUpdateGroup)."
                }
                catch 
                {
                    Write-Output "Unable to add $($NewComputer.SamAccountName) to $($AutoUpdateGroup)."
                    Write-Output "$($Error[0])"
                }
            }
        }
    }
}

if (!($VIServer))
{
    $VIServer = "ht-vcenter"
}

Connect-VIServer -Server $VIServer

$VMExists = Get-VM -Name $VMName -ErrorAction SilentlyContinue
if ($VMExists)
{
    Write-Output "VM with name $($VMName) already exists."
    break
}
else 
{
    Write-Output "Creating $($VMName)."    
}

[int]$VMCpuPerSocket = $VMvCPU/2

$VMResourcePool = Get-Cluster -Name $VMCluster
$DataStore = Get-Datastore -Name $VMDatastore -Datacenter $VMDataCenter

if ($VMTemplate)
{
    if ($VMTemplate -eq "tpl-2012r2std")
    {
        $GuestOS = '2012'
        $Template = Get-Template -Name $VMTemplate
        $VMOSCustomization = Get-OSCustomizationSpec -Name "AutomationX_Windows2012R2STD" #You'll probably want to specify your own OS Customization Specification
    }
    if (($VMTemplate -eq "tpl-2016core") -or ($VMTemplate -eq "tpl-2016std") -or ($VMTemplate -eq 'se-tpl-2016std') -or ($VMTemplate -eq 'se-tpl-2016core'))
    {
        $GuestOS = '2016'
        $Template = Get-Template -Name $VMTemplate
        $VMOSCustomization = Get-OSCustomizationSpec -Name "AutomationX_Windows2016STD" #You'll probably want to specify your own OS Customization Specification
    }

    New-VM -Name $VMName -Location $VMFolder -Datastore $DataStore -Template $Template -OSCustomizationSpec $VMOSCustomization -ResourcePool $VMResourcePool -Server $VIServer
    Start-Sleep -Seconds 10
    $NewVM = Get-VM -Name $VMName
    if ($NewVM)
    {
        Set-VM -VM $NewVM -NumCpu $VMvCPU -MemoryGB $VMMemGB -CoresPerSocket $VMCpuPerSocket -Verbose -Confirm:$false
        $Nic = Get-NetworkAdapter -VM $NewVM
        Set-NetworkAdapter -NetworkAdapter $Nic -NetworkName $VMNetwork -Verbose -Confirm:$false 
        Get-VM -Name $NewVM | Set-Annotation -CustomAttribute Spx.AutomationX.CreationDate -Value (Get-Date)
        Get-VM -Name $NewVM | Set-Annotation -CustomAttribute Spx.AutomationX.BusinessOwner -Value $VMBusinessOwner
        Get-VM -Name $NewVM | Set-Annotation -CustomAttribute Spx.AutomationX.Owner -Value $VMOwner
        Get-VM -Name $NewVM | Set-Annotation -CustomAttribute Spx.Description -Value $VMDescription        
        Start-VM -VM $NewVM -Verbose
        Set-ADcomputer -Identity $VMName -Description $VMDescription
        if ($VMDiskSize)
        {
            $Disk = Get-HardDisk -VM $NewVM
            Set-HardDisk -HardDisk $Disk -CapacityGB $VMDiskSize
        }
    } 
}
elseif (!($VMTemplate))
{
    if ($GuestOS -eq "2012")
    {
        $GuestOS = "windows8Server64Guest"
    }
    if ($GuestOS -eq "2016")
    {
        $GuestOS = "windows10Server64Guest"
    }
    New-VM -Name $VMName -Location $VMFolder -Datastore $DataStore -ResourcePool $VMResourcePool -Server $VIServer -NetworkName $VMNetwork -DiskStorageFormat Thin -DiskGB $VMDiskSize
    Start-Sleep -Seconds 10
    $NewVM = Get-VM -Name $VMName
    if ($NewVM)
    {
        Set-VM -VM $NewVM -NumCpu $VMvCPU -MemoryGB $VMMemGB -CoresPerSocket $VMCpuPerSocket -Confirm:$false
        $Nic = Get-NetworkAdapter -VM $NewVM
        Set-NetworkAdapter -NetworkAdapter $Nic -Type Vmxnet3 -Confirm:$false 
        $Scsi = Get-ScsiController -VM $NewVM 
        Set-ScsiController -ScsiController $Scsi -Type VirtualLsiLogicSAS -BusSharingMode NoSharing -Confirm:$false
        Get-VM -Name $NewVM | Set-Annotation -CustomAttribute Spx.AutomationX.CreationDate -Value (Get-Date)
        Get-VM -Name $NewVM | Set-Annotation -CustomAttribute Spx.AutomationX.BusinessOwner -Value $VMBusinessOwner
        Get-VM -Name $NewVM | Set-Annotation -CustomAttribute Spx.AutomationX.Owner -Value $VMOwner
        Get-VM -Name $NewVM | Set-Annotation -CustomAttribute Spx.Description -Value $VMDescription        
        Start-VM -VM $NewVM -Verbose
        Set-ADcomputer -Identity $VMName -Description $VMDescription
        if ($VMDiskSize)
        {
            $Disk = Get-HardDisk -VM $NewVM
            Set-HardDisk -HardDisk $Disk -CapacityGB $VMDiskSize -Confirm:$false
        }
    }
}

$RunningUser = $env:USERNAME
$Admin = Get-ADUser -Identity $RunningUser -Properties EmployeeID
$EmployeeID = $Admin.EmployeeID
$User = Get-ADUser -filter {EmployeeNumber -eq $EmployeeID} -Properties EmployeeNumber,mail -ErrorAction SilentlyContinue
$mail = $User.mail
$NotificationJob = {
    $count = 0
    do {
        Start-Sleep -Seconds 30
        try 
        {
            Clear-DnsClientCache
            $Online = Test-WSMan -ComputerName $Using:VMName
        }
        catch
        {   
        }
        $count++
    } while (!($Online) -and ($count -le 30))
    $EmailBody = "$($Using:VMName) is online."
    $User = "anonymous"
    $to = "$($Using:mail)"
    $PWord = ConvertTo-SecureString -String "anonymous" -AsPlainText -Force
    $Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pword
    Send-MailMessage -To $to -From $Using:SendingAddress -Subject "$($Using:VMName) is online." -Body $EmailBody -SmtpServer $Using:MailServerSMTPAddress -Credential $creds         
}
Start-Job -Name 'VMNotification' -ScriptBlock $NotificationJob