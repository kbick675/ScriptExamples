param(
    [Parameter(Mandatory=$true)]
    [string]
    $targetSystem='localhost',
    [Parameter(Mandatory=$true)]
    [string]
    $driveLetter
)

if (Test-WSMan -ComputerName $targetSystem -ErrorAction SilentlyContinue)
{
    Write-Output "Rescaning disks on $($targetSystem)..."
    Update-HostStorageCache -CimSession $targetSystem
    Write-Output "Getting partition information for $($driveLetter) on $($targetSystem)..."
    $partition = Get-Partition -DriveLetter $driveLetter -CimSession $targetSystem
    Write-Output "Getting max size of partition $($partition.PartitionNumber) for $($partition.DriveLetter) on $($targetSystem)..."
    $size = Get-PartitionSupportedSize -DiskNumber $partition.DiskNumber -PartitionNumber $Partition.PartitionNumber -CimSession $targetSystem
    Write-Output "Max size of $($partition.PartitionNumber) for $($partition.DriveLetter) on $($targetSystem) is $($size.SizeMax)."
    Write-Output "Setting size of $($partition.PartitionNumber) for $($partition.DriveLetter) on $($targetSystem) to $($size.SizeMax)."
    Resize-Partition -DiskNumber $partition.DiskNumber -PartitionNumber $partition.PartitionNumber -Size $size.SizeMax -CimSession $targetSystem
    Write-Output "Complete."
}
