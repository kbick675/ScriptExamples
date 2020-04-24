<#
.SYNOPSIS
Creates a new VM in vCenter via the PowerCli cmdlets. 
.OUTPUTS
Results are output to screen.
.PARAMETER Name
Specifies the name of the account to create.
.PARAMETER Template
Creates the VM from the specified VM template. 
.PARAMETER Cluster
Creates the VM in the specified cluster. 
Do no specify if specifying ResourcePool. 
.PARAMETER ResourcePool
Creates the VM in the specified resource pool. 
Do not specify if specifying Cluster. 
.PARAMETER Network
Sets the VM network adapter to the specified VM network.
.PARAMETER Datastore
Creates the VM in the specified datastore. Used if targeting a specific volume or host. Do not just in conjunction with DatastoreCluster.
.PARAMETER Datacenter
The datacenter you'll be creating the VM in.
.PARAMETER VIServer
Determines which vCenter server the commands run against. 
.PARAMETER PrimaryDiskSize
Sets primary VM disk to 60, 80 or 100 GB. 
.PARAMETER AdditionalDiskSize
Flags for an additional disk to be created and sets the size of the disk.
.PARAMETER AdditionalDiskThick
Switch to set the additional disk to be thick provisioned.
.PARAMETER VMvCPU
Sets the VM to the specified number of CPUs.
.PARAMETER VMMemGB
Sets the VM to the specified amount of memory in GB.
.PARAMETER TargetOU
Places the VM account in one of the specified Organizational Units (OU).
.PARAMETER AutoUpdateGroup
Puts the VM AD Account in one of the specified security groups that determine auto update scheduling. 
.PARAMETER Notes
Notes for the VM. Also goes into AD computer account description. 
.PARAMETER NoDomain
For when you don't want to join a domain. 
.PARAMETER IPAddress
IP address for static addressing
.PARAMETER SubnetMask
Subnet mask for static addressing
.PARAMETER Gateway
Gateway IP for static addressing
.PARAMETER DNSServers
DNS Servers for static addressing
.EXAMPLE
$Requestor = "Requestor Name"
$Department = "Corporate Engineering"
$Environment = "Production"
$Engineer = "Engineer Name"
$Type = "ExampleVM"
$Notes = "Department - $($Department)`nRequestor - $($Requestor)`nEnvironment - $($Environment)`nIT Engineer - $($Engineer)`nNotes - $Type"


$splat = @{
    Name = "examplevm1"
    Template = "WinGui2019-tpl"
    Cluster = "vCenterCluster1"
    Network = "VLAN 170 - Engineering Automation - PROD"
    DataStore = "StorageCluster1"
    VIServer = "vCenter1"
    VMvCPU = 2
    VMMemGB = 4
    Notes = $Notes
    Folder = "Systems_Engineering"
}

.\New-PowerCliVM.ps1 @splat
.NOTES
Written by: Kevin Bickmore
#>

param(
    [Parameter(Mandatory=$true,Position=0)]
    [ValidateNotNull()]
    [string]$Name,
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [ValidateSet("WinCore2016-tpl","WinCore2019-tpl","WinGui2016-tpl","WinGui2019-tpl","Centos-tpl")]
    [string]$Template,
    [ValidateSet("vCenterCluster1","vCenterCluster2")]
    [string]$Cluster,
    [string]$ResourcePool,
    [string]$Folder,
    [string]$Network,
    [string]$DataStore = "StorageCluster1",
    [ValidateNotNull()]
    [ValidateSet("DataCenter1","DataCenter2")]
    [string]$DataCenter = 'DataCenter1',
    [ValidateSet("vcenter1","vcenter2")]
    [string]$VIServer = "vcenter1",
    [ValidateSet(80,100,120)]
    [decimal]$PrimaryDiskSize,
    [decimal]$AdditionalDiskSize,
    [switch]$AdditionalDiskDoNotStoreWithVM,
    [switch]$AdditionalDiskThick,
    [ValidateSet(1,2,4,6,8,12,16)]
    [int]$VMvCPU = 2,
    [ValidateSet(2,4,6,8,12,16,32)]
    [int]$VMMemGB = 4,
    [string]$TargetOU,
    [string]$AutoUpdateGroup,
    [string]$Notes,
    [switch]$NoDomain,
    [string]$IPAddress,
    [string]$SubnetMask,
    [string]$Gateway,
    [string[]]$DNSServers,
    [ValidateSet("Windows","CentOS7","RHEL7")]
    [string]$GuestOS = "Windows"
    )


$MailServerSMTPAddress = "smtp.domain.com"
$SendingAddress = "NewPowerCliVM@domain.com"

if (!(Get-Module -ListAvailable -Name VMware.PowerCLI))
{
    Write-Output "PowerCLI is not installed. Please install from Powershell Gallery: Install-Module VMware.PowerCLI"
    Write-Output "Stopping..."
    Exit
}
if ($PSVersionTable.PSEdition -eq "Core")
{
    "This version of Powershell does not support the AD Cmdlets. Any functionality that relies on them will not work."
}

### AD Computer Account Creation
if ($PSVersionTable.PSEdition -ne "Core")
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
        Exit
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
                Move-ADObject -Identity $NewComputer -TargetPath $TargetOU -Verbose
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

### Check if we're connected to a VIServer
function ConnectVCenterServer 
{
    param (
        [string] $vcenter_server = "*" 
    )
	Connect-VIServer -Server $vcenter_server
}
function CheckVIServerConnection
{
    param (
        [string] $vcenter_server
    ) 
	$connected = $FALSE
    if ($global:DefaultVIServers.Count -gt 0) 
    {
        $ServersFiltered = $global:DefaultVIServers.Where{$_.Name -eq "$($vcenter_server)"}
        if ($ServersFiltered.IsConnected -eq $true)
        {
			Write-Output "Already connected to $($vcenter_server); continuing"
			$connected = $TRUE
        }
        elseif ($ServersFiltered.IsConnected -eq $false)
        {
            Write-Output "Attempting to connect to $($vcenter_server)"
		    $connected = if (ConnectVCenterServer -vcenter_server $vcenter_server) { $TRUE } else { $FALSE }
        }
        return $connected
    }
    elseif (!($global:DefaultVIServers))
    {
        Write-Output "Attempting to connect to $($vcenter_server)"
        $connected = if (ConnectVCenterServer -vcenter_server $vcenter_server) { $TRUE } else { $FALSE }
        return $connected
    }
}
if (!(CheckVIServerConnection -vcenter_server $VIServer)) 
{
	Write-Output "Unable to connect to $($VIServer)"
	Exit
}
### End vCenter Connectivity Check

### Check if VM Exists
$VMExists = Get-VM -Name $Name -ErrorAction SilentlyContinue
if ($VMExists)
{
    Write-Output "VM with name $($Name) already exists. Stopping..."
    Exit
}
else 
{
    Write-Output "Creating $($Name)."    
}

### Set Cpus per socket assuming a 2 socket system
if ($VMvCPU -gt 1)
{
    [int]$VMCpuPerSocket = $VMvCPU/2
}
else 
{
    [int]$VMCpuPerSocket = 1
}

### Get specified Datacenter information
if ($DataCenter)
{
    $DataCenter = Get-Datacenter -Name $DataCenter -Server $VIServer
}

### Get Resource Pool/Cluster information
if ($ResourcePool)
{
    $ResourcePool = Get-ResourcePool -Name $ResourcePool -Location $DataCenter -Server $VIServer
}
elseif ($Cluster)
{
    $ResourcePool = Get-Cluster -Name $Cluster -Location $DataCenter -Server $VIServer
}

### Get Datastore/Datastore Cluster information

if ($DatastoreName)
{
    try 
    {
        $Datastore = Get-DatastoreCluster -Name $DataStoreName -Location $DataCenter -Server $VIServer -ErrorAction SilentlyContinue
    }
    catch {}
    try 
    {
        $Datastore = Get-Datastore -Name $DataStoreName -Location $DataCenter -Server $VIServer -ErrorAction SilentlyContinue
    }
    catch {}
    switch -wildcard ($Datastore.Id) 
    {
        "StoragePod*" 
        {
            if ($DataStore.FreeSpaceGB -lt '1000.00')
            {
                Write-Warning -Message "$($DataStore.Name) has less than 1TB of free space."
                Write-Warning -Message "$($DataStore.Name) has $($DataStore.FreeSpaceGB) available."
            }
            elseif ($DataStore.FreeSpaceGB -lt '2000.00')
            {
                Write-Warning -Message "$($DataStore.Name) has less than 2TB of free space."
                Write-Warning -Message "$($DataStore.Name) has $($DataStore.FreeSpaceGB) available."
            }  
        }
        "DataStore*" 
        {
            if ($DataStore.FreeSpaceGB -lt '500.00')
            {
                Write-Warning -Message "$($DataStore.Name) has less than 500GB of free space."
                Write-Warning -Message "$($DataStore.Name) has $($DataStore.FreeSpaceGB) available."
            }
            elseif ($DataStore.FreeSpaceGB -lt '1000.00')
            {
                Write-Warning -Message "$($DataStore.Name) has less than 1TB of free space"
                Write-Warning -Message "$($DataStore.Name) has $($DataStore.FreeSpaceGB) available."
            }
        }
        
        Default {}
    }
}

### Get folder information
if ($Folder)
{
    try 
    {
        $FolderId = Get-Folder -Name $Folder -Location $DataCenter -Server $VIServer
    }
    catch
    {
        Write-Output "Specified folder doesn't seem to exist in $($Datacenter.Name)"
        $Folder = Get-Folder -Name vm -Location $DataCenter -Server $VIServer
        $FolderId = $Folder.Id
        Write-Output "VM will be placed in generic VM folder for $($Datacenter.Name)"
    }
}
elseif (!($Folder))
{
    $Folder = Get-Folder -Name vm -Location $DataCenter -Server $VIServer
    $FolderId = $Folder.Id
}

if ($VMTemplate)
{
    if (($Template -eq 'phCentos-tpl') -or ($Template -eq 'laCentos-tpl'))
    {
        $TemplateName = (Get-Template -Name $Template -Server $VIServer).Name
        $OSCustomization = Get-OSCustomizationSpec -Name "CentOS" -Server $VIServer
    }
    else 
    {
        $TemplateName = (Get-Template -Name $Template -Server $VIServer).Name
        if (!($NoDomain))
        {
            if ($IPAddress)
            {
                $OSCustomization = Get-OSCustomizationSpec -Name "Windows_Server_Domain_Join_StaticIP" -Server $VIServer
                $OSCustomization | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $IPAddress -SubnetMask $SubnetMask -DefaultGateway $Gateway -Dns $DNSServers -Server $VIServer
            }
            elseif (!($IPAddress))
            {
                $OSCustomization = Get-OSCustomizationSpec -Name "Windows_Server_Domain_Join" -Server $VIServer
            }
        }
        elseif ($NoDomain)
        {
            $OSCustomization = Get-OSCustomizationSpec -Name "Windows_Server_NoDomain" -Server $VIServer
        }
    }

    $NewVMSplat = @{
        Name = $Name
        Location = $FolderId
        Datastore = $DataStore
        Template = $TemplateName
        OSCustomizationSpec = $OSCustomization
        ResourcePool = $ResourcePool
        Server = $VIServer
    }
    New-VM @NewVMSplat
    Start-Sleep -Seconds 10
    $NewVM = Get-VM -Name $VMName
    if ($NewVM)
    {
        $SetVMSplat = @{
            VM = $NewVM
            NumCpu = $VMvCPU
            MemoryGB = $VMMemGB
            CoresperSocket = $VMCpuPerSocket
            Verbose = $true
            Confirm = $false
            Server = $VIServer
        }
        Set-VM @SetVMSplat
        $Nic = Get-NetworkAdapter -VM $NewVM -Server $VIServer
        if ($Network)
        {
            Set-NetworkAdapter -NetworkAdapter $Nic -NetworkName $Network -StartConnected $true -Verbose -Confirm:$false -Server $VIServer
        }
        if ($PrimaryDiskSize)
        {
            $Disk = Get-HardDisk -VM $NewVM -Server $VIServer
            Set-HardDisk -HardDisk $Disk -CapacityGB $PrimaryDiskSize -Confirm:$false -Server $VIServer
        }
        if ($AdditionalDiskSize)
        {
            if ($AdditionalDiskDoNotStoreWithVM)
            {
                $Disk = $NewVM | Get-HardDisk -Server $VIServer
                $antiAffinityRule = New-Object 'VMware.VimAutomation.ViCore.Types.V1.DatastoreManagement.SdrsVMDiskAntiAffinityRule' $Disk

                if ($AdditionalDiskThick)
                {
                    New-HardDisk -VM $NewVM -CapacityGB $AdditionalDiskSize -Datastore $DataStoreCluster -AdvancedOption $antiAffinityRule -Server $VIServer
                }
                else 
                {
                    New-HardDisk -VM $NewVM -CapacityGB $AdditionalDiskSize -StorageFormat Thin -Datastore $DataStoreCluster -AdvancedOption $antiAffinityRule -Server $VIServer
                }
            }
            elseif (!($AdditionalDiskDoNotStoreWithVM))
            {
                if ($AdditionalDiskThick)
                {
                    New-HardDisk -VM $NewVM -CapacityGB $AdditionalDiskSize -Server $VIServer
                }
                else 
                {
                    New-HardDisk -VM $NewVM -CapacityGB $AdditionalDiskSize -StorageFormat Thin -Server $VIServer
                }
            }
        }
        if ($Notes)
        {
            Set-VM -VM $NewVM -Notes $Notes -Confirm:$false -Server $VIServer
        }
        Start-VM -VM $NewVM -Verbose -Server $VIServer
    } 
}
### Create blank VM
elseif (!($Template))
{
    switch ($GuestOS) {
        "Windows" { $GuestOS = "windows10Server64Guest" }
        "CentOS7" { $GuestOS = "centos764Guest" }
        "RHEL7" { $GuestOS = "rhel7_64Guest" }
        Default {}
    }
    $NewVMSplat = @{
        Name = $Name
        Location = $FolderName
        Datastore = $DataStore
        ResourcePool = $ResourcePool
        Server = $VIServer
        NetworkName = $Network
        DiskStorageFormat = 'Thin'
        DiskGB = $PrimaryDiskSize
        NumCpu = $VMvCPU
        MemoryGB = $VMMemGB
        CoresperSocket = $VMCpuPerSocket
    }
    New-VM @NewVMSplat
    Start-Sleep -Seconds 10
    $NewVM = Get-VM -Name $Name
    if ($NewVM)
    {
        $Nic = Get-NetworkAdapter -VM $NewVM -Server $VIServer
        if ($Network)
        {
            Set-NetworkAdapter -NetworkAdapter $Nic -NetworkName $Network -Verbose -Confirm:$false -Type Vmxnet3 -Server $VIServer
        }
        if ($PrimaryDiskSize)
        {
            $Disk = Get-HardDisk -VM $NewVM -Server $VIServer
            Set-HardDisk -HardDisk $Disk -CapacityGB $PrimaryDiskSize -Confirm:$false -Server $VIServer
        }
        if ($AdditionalDiskSize)
        {
            if ($AdditionalDiskDoNotStoreWithVM)
            {
                $Disk = $NewVM | Get-HardDisk
                $antiAffinityRule = New-Object 'VMware.VimAutomation.ViCore.Types.V1.DatastoreManagement.SdrsVMDiskAntiAffinityRule' $Disk

                if ($AdditionalDiskThick)
                {
                    New-HardDisk -VM $NewVM -CapacityGB $AdditionalDiskSize -Datastore $DataStoreCluster -AdvancedOption $antiAffinityRule -Server $VIServer
                }
                else 
                {
                    New-HardDisk -VM $NewVM -CapacityGB $AdditionalDiskSize -StorageFormat Thin -Datastore $DataStoreCluster -AdvancedOption $antiAffinityRule -Server $VIServer
                }
            }
            elseif (!($AdditionalDiskDoNotStoreWithVM))
            {
                if ($AdditionalDiskThick)
                {
                    New-HardDisk -VM $NewVM -CapacityGB $AdditionalDiskSize -Server $VIServer
                }
                else 
                {
                    New-HardDisk -VM $NewVM -CapacityGB $AdditionalDiskSize -StorageFormat Thin -Server $VIServer
                }
            }
        }
        if ($Notes)
        {
            Set-VM -VM $NewVM -Notes $Notes -Confirm:$false -Server $VIServer
            Set-ADcomputer -Identity $Name -Description $Notes -Server $VIServer
        }
        Start-VM -VM $NewVM -Verbose -Server $VIServer
    }
}

### This job will run for Windows systems. realm domain joins can place them in their particular OU themselves. 
if (($Template -notlike "*CentOS*") -or ($PSVersionTable.PSEdition -ne "Core"))
{
    $ADJob = {
        $count = 0
        do {
            Start-Sleep -Seconds 30
            try 
            {
                Clear-DnsClientCache
                $Online = Test-WSMan -ComputerName $Using:Name
            }
            catch
            {   
            }
            $count++
        } while (!($Online) -and ($count -le 30))
        if ($Online)
        {
            $ADAccount = Get-ADComputer -Identity $Using:Name
            if (!($Using:TargetOU))
            {
                Write-Output "$($Using:Name) is in: $($Domain.ComputersContainer)"
            }
            elseif ($Using:TargetOU)
            {
                if ($ADAccount.DistinguishedName -like "*$($Domain.ComputersContainer)")
                {
                    Write-Output "Attempting move to $($Using:TargetOU)."
                    try 
                    {
                        Move-ADObject -Identity $ADAccount -TargetPath $Using:TargetOU
                        Write-Output "Move successful."
                    }
                    catch
                    {
                        Write-Output "Move failed."
                        Write-Output "$($Error[0])"
                    }
                }
            }
            if ($Using:Notes)
            {
                Set-ADcomputer -Identity $ADAccount.SamAccountName -Description $Using:Notes -Confirm:$false
            }
            if ($Using:AutoUpdateGroup)
            {
                try 
                {
                    Add-ADGroupMember -Identity $Using:AutoUpdateGroup -Members $ADAccount.SamAccountName
                    Write-Output "Added $($ADAccount.SamAccountName) to $($Using:AutoUpdateGroup)."
                }
                catch 
                {
                    Write-Output "Unable to add $($ADAccount.SamAccountName) to $($Using:AutoUpdateGroup)."
                    Write-Output "$($Error[0])"
                }
            }
        }
    }
    Start-Job -Name 'ADJob' -ScriptBlock $ADJob
}

$RunningUser = $env:USERNAME
$Admin = Get-ADUser -Identity $RunningUser -Properties EmployeeID
## This assumes you're mapping your admin account that is running this to the regular/primary user account of the employee
## via the employeeID and employeeNumber attributes.
if ($Admin.EmployeeID)
{
    $User = Get-ADUser -filter {EmployeeNumber -eq $Admin.EmployeeID} -Properties EmployeeNumber,mail -ErrorAction SilentlyContinue
    $mail = $User.mail
}
##
elseif (!($Admin.EmployeeID))
{
    $mail = Read-Host -Prompt "Email address to send VM online notification to"
}
$NotificationJob = {
    $count = 0
    do {
        Start-Sleep -Seconds 30
        try 
        {
            Clear-DnsClientCache
            $Online = Test-WSMan -ComputerName $Using:Name
        }
        catch
        {   
        }
        $count++
    } while (!($Online) -and ($count -le 30))
    $EmailBody = "$($Using:Name) is online."
    $User = "anonymous"
    $to = "$($Using:mail)"
    $PWord = ConvertTo-SecureString -String "anonymous" -AsPlainText -Force
    $Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pword
    Send-MailMessage -To $to -From $Using:SendingAddress -Subject "$($Using:Name) is online." -Body $EmailBody -SmtpServer $Using:MailServerSMTPAddress -Credential $creds         
}
Start-Job -Name 'VMNotification' -ScriptBlock $NotificationJob