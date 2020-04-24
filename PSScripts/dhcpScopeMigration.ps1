#requires -version 5.1 
#requires -PSEdition Desktop
#requires -modules 'powershell-yaml', 'swispowershell', 'posh-git'

param (
    # BranchOfficeID
    # Length must be 4 or 5 characters
    [ValidateLength(4,5)]
    [Parameter(Mandatory=$true)]
    [string]
    $BranchOfficeID,
    # Destination DHCP Server
    [Parameter(Mandatory=$true)]
    [string]
    $DestinationDhcpServer,
    # Partner DHCP Server
    [Parameter(Mandatory=$true)]
    [string]
    $partnerDhcpServer,
    # Working Branch Name
    [Parameter(Mandatory=$true)]
    [string]
    $branchName,
    # Ansible Proxy Box. aka. server that runs ansible
    [Parameter(Mandatory=$true)]
    [string]
    $ansibleProxyHostname
)

BEGIN
{
    $ScriptPath = (Split-Path $script:MyInvocation.MyCommand.Path)
    $StartingPath = Get-Location
    Push-Location $ScriptPath

    #region Get DHCP Server for Branch Office
    function getDhcpServer { 
        $DHCPServer = (Get-DhcpServerInDC | where DnsName -like "H$($BranchOfficeID)-dc*")
        if ($DHCPServer.count -ge 2)
        {
            Write-Output "There are $($DHCPServer.count) entries that match H$($BranchOfficeID)-dc*."
            Write-Output "Remove unused entries before continuing."
            $DHCPServer
            Exit
        }
        else
        {
            return $DHCPServer.DnsName
        }
    }
    Write-Output "Getting DHCP servers that match $($BranchOfficeID)..."
    $sourceDhcpServerName = getDhcpServer
    Write-Output "Found: $($sourceDhcpServerName)"
    #endregion 

    #region check connectivity to source DHCP server
    function testConnectivity {
        param (
            [Parameter(Mandatory=$true)]
            [string]
            $ServerToTest
        )
        if (Test-WSMan -ComputerName $ServerToTest)
        {
            Write-Output "Connection to $($ServerToTest): Successful"
        }
        elseif (!(Test-WSMan -ComputerName $ServerToTest))
        {
            Write-Output "Connection to $($ServerToTest): Failed"
            Write-Host -ForegroundColor Red $Error[0].Exception
            Exit
        }
    }
    Write-Output "--- Testing Server Connectivity ---"
    testConnectivity -ServerToTest $sourceDhcpServerName
    testConnectivity -ServerToTest $DestinationDhcpServer
    testConnectivity -ServerToTest $partnerDhcpServer
    #endregion

    #region Get Server Info

    Write-Output "--- Getting Source Server Info ---"
    $sourceServerOptionDefinitions = Get-DhcpServerv4OptionDefinition -ComputerName $sourceDhcpServerName
    $sourceServerOptions = Get-DhcpServerv4OptionValue -ComputerName $sourceDhcpServerName
    $sourceServerCustomVendorClasses = Get-DhcpServerv4Class -Type Vendor -ComputerName $sourceDhcpServerName | where Name -NotLike "Microsoft*"
    $sourceServerScopes = Get-DhcpServerv4Scope -ComputerName $sourceDhcpServerName
    
    Write-Output "--- Getting Destination Server Info ---"
    $destServerOptionDefinitions = Get-DhcpServerv4OptionDefinition -ComputerName $DestinationDhcpServer

    Write-Output "--- Getting Partner Server Info ---"
    $partnerServerOptionDefinitions = Get-DhcpServerv4OptionDefinition -ComputerName $partnerDhcpServer 
    #endregion

    #region Ensure working branch is set. 
    $currentBranch = Get-GitBranch
    if ($currentBranch -like "*$($branchName)*")
    {
        Write-Output "Current branch is: $($currentBranch)..."
        Write-Output "Continuing..."
    }
    elseif ($currentBranch -notlike "*$($branchName)*")
    {
        Write-Output "Current branch is: $($currentBranch)"
        Write-Output "Changing to $($branchName)"
        try {
            git checkout $branchName
        }
        catch {
            $Error[0]
            Exit
        }
    }
    #endregion

    #region create ansible inventory file for hospital
    
    function getSwitches
    {
        #$creds = Get-Credential -Message "The username you use for connecting to Solarwinds Orion:"
        try {
            $swis = Connect-Swis -Trusted -Hostname phvcaorionp01
            $query = Get-SwisData -SwisConnection $swis -Query 'SELECT NodeName,IPAddress,Vendor,Status FROM Orion.Nodes WHERE NodeName LIKE @v' -Parameters  @{ v = "H$($BranchOfficeID)%sw%" }
        }
        catch {
            Write-Host -ForegroundColor Magenta "There was an error getting switch information from Orion."
            Write-Host "Stopping..."
            Exit
        }
        return $query
    }
    $switchList = getSwitches
    $switchList
    Write-Output "---"
    function createYamlForAnsible
    {
        param(
            # switch list
            [Parameter(Mandatory=$true)]
            [System.Array]
            $switch
        )
        
        if ($switch[0].Vendor -eq "Cisco")
        {
            $switchOS = "ios"
            $ansible_network_os = "ios"
            $ansible_connection = "network_cli"
        }
        elseif ($switch[0].Vendor -eq "HP") 
        {
            $switchOS = "aruba"
            $ansible_network_os = "aruba"
            $ansible_connection = "ssh"
        }

        $yaml = @{"$($switchOS)" = 
            @{"hosts" = @{}}
        }

        foreach ($node in $switch)
        {
            if (($yaml."$($switchOS)".hosts).count -eq 0)
            {
                $yaml."$($switchOS)" = @{"hosts" = @(
                    @{"$($node.NodeName)" = @(
                        @{"ansible_host"="$($node.IPAddress)"}
                        )
                    }
                    )
                }
            }
            elseif (($yaml."$($switchOS)".hosts).count -ge 1) {
                $yaml."$($switchOS)".hosts += @(
                    @{"$($node.NodeName)" = @(
                        @{"ansible_host"="$($node.IPAddress)"}
                        )
                    }   
                )
            }
        }

        $yaml."$($switchOS)" += @{"vars"= @(
            @{"ansible_network_os"="$($ansible_network_os)"}
            @{"ansible_connection"="$($ansible_connection)"}
            )
        }
        $yamlOutput = ConvertTo-Yaml -Data $yaml
        return $yamlOutput
    }

    $yamlData = createYamlForAnsible -switch $switchList
    Write-Output "YAML Output:"
    $yamlData = $yamlData.Replace("- ","  ")
    $yamlData
    $inventoryPath = "..\..\Ansible\iOSSwitch\ip_helper\hosts"
    $filePath = "$($inventoryPath)\H$($BranchOfficeID).yml"
    if (Test-Path $filePath)
    {
        Write-Output "Inventory file for H$($BranchOfficeID) already exists..."
    }
    elseif (!(Test-Path $filePath)) 
    {
        Write-Output "Outputting inventory file for H$($BranchOfficeID)..."
        Write-Output "Output path is: $($filePath)"
        $yamlData | Out-File -FilePath $filePath -Encoding utf8

    }
    try {
        Push-Location $inventoryPath
        git add "H$($BranchOfficeID).yml"
        git commit -m "adding inventory file for H$($BranchOfficeID)"
        git push
    }
    catch {
        Write-Output "Check Git output for errors..."
        Write-Output "Stopping..."
        Exit
    }
    #endregion
}

PROCESS
{
    #region vendor class migration
    Write-Output "--- Vendor Class Migration ---"
    foreach ($vendorClass in $sourceServerCustomVendorClasses)
    {
        if (Get-DhcpServerv4Class -Name $vendorClass.Name -Type Vendor -ComputerName $DestinationDhcpServer -ErrorAction SilentlyContinue)
        {
            Write-Output "$($vendorClass.Name) already exists on $($DestinationDhcpServer)."
        }
        else 
        {
            Write-Output "$($vendorClass.Name) does not exist on $($DestinationDhcpServer)."
            Write-Output "Adding vendor class $($vendorClass.Name) on $($DestinationDhcpServer)..."
            $vendorClassSplat = @{
                Name = $vendorClass.Name
                Type = "Vendor"
                Data = $vendorClass.Data
                Description = $vendorClass.Description
                ComputerName = $DestinationDhcpServer
            }
            try {
                Add-DhcpServerv4Class @vendorClassSplat -Verbose
            }
            catch {
                Write-Host -ForegroundColor Red "ERROR: Failed to add $($vendorClass.Name) to $($DestinationDhcpServer)."
                Write-Output "--- Exception ---"
                Write-Host -ForegroundColor Red $Error[0].Exception
                Write-Output "--- Exception ---"
            }   
        }
        if (Get-DhcpServerv4Class -Name $vendorClass.Name -Type Vendor -ComputerName $partnerDhcpServer -ErrorAction SilentlyContinue)
        {
            Write-Output "$($vendorClass.Name) already exists on $($partnerDhcpServer)."
        }
        else 
        {
            Write-Output "$($vendorClass.Name) does not exist on $($partnerDhcpServer)."
            Write-Output "Adding vendor class $($vendorClass.Name) on $($partnerDhcpServer)..."
            $vendorClassSplat = @{
                Name = $vendorClass.Name
                Type = "Vendor"
                Data = $vendorClass.Data
                Description = $vendorClass.Description
                ComputerName = $partnerDhcpServer
            }
            try {
                Add-DhcpServerv4Class @vendorClassSplat -Verbose
            }
            catch {
                Write-Host -ForegroundColor Red "ERROR: Failed to add $($vendorClass.Name) to $($partnerDhcpServer)."
                Write-Output "--- Exception ---"
                Write-Host -ForegroundColor Red $Error[0].Exception
                Write-Output "--- Exception ---"
            }   
        }
    }
    #endregion 

    #region server option definition migration
    Write-Output "--- Option Definition Migration ---"
    function optionDefMigration
    {
        param(
            # Option IDs to Move
            [Parameter(Mandatory=$true)]
            $optionIdsToMove,
            [string]$sourceDhcpServer,
            [string]$targetDhcpServer
        )
        Write-Output "Migrating custom server options from $($sourceDhcpServer) to $($targetDhcpServer)"
        foreach ($optionId in $optionIdsToMove.OptionId)
        {
            $getTargetServerOptionSplat = @{
                OptionId = $OptionId
                ComputerName = $targetDhcpServer
            }
            if (Get-DhcpServerv4OptionDefinition @getTargetServerOptionSplat -ErrorAction SilentlyContinue)
            {
                Write-Output "Option ID $($OptionID) already exists on $($targetDhcpServer)."
            }
            else 
            {
                Write-Output "Option ID $($OptionID) does not exist on $($targetDhcpServer)."
                Write-Output "Adding option ID $($optionID) on $($targetDhcpServer)..."
                $serverOptionDefinition = Get-DhcpServerv4OptionDefinition -OptionId $optionId -ComputerName $sourceDhcpServer
                $serverOptionDefSplat = @{
                    Name = $serverOptionDefinition.Name
                    OptionId = $serverOptionDefinition.OptionId
                    Description = $serverOptionDefinition.Description
                    Type = $serverOptionDefinition.Type
                    MultiValued = $serverOptionDefinition.MultiValued
                    ComputerName = $targetDhcpServer
                }
                try {
                    Add-DhcpServerv4OptionDefinition @serverOptionDefSplat -Verbose
                }
                catch {
                    Write-Host -ForegroundColor Red "ERROR: Failed to add option $($serverOptionDefinition.OptionId) $($serverOptionDefinition.Name) to $($targetDhcpServer)."
                    Write-Output "--- Exception ---"
                    Write-Host -ForegroundColor Red $Error[0].Exception
                    Write-Output "--- Exception ---"
                }   
            }
        }    
    }

    $diff = Compare-Object -ReferenceObject $sourceServerOptionDefinitions -DifferenceObject $destServerOptionDefinitions -Property OptionId
    $optionIdsToMove = $diff | where SideIndicator -eq '<=' | select OptionId
    if ($optionIdsToMove -ne $null)
    {
        optionDefMigration -optionIdsToMove $optionIdsToMove.OptionId -sourceDhcpServerName $sourceDhcpServerName -DestinationDhcpServer $DestinationDhcpServer
    }

    $diff = $null
    $optionIdsToMove = $null
    $diff = Compare-Object -ReferenceObject $sourceServerOptionDefinitions -DifferenceObject $partnerServerOptionDefinitions -Property OptionId
    $optionIdsToMove = $diff | where SideIndicator -eq '<=' | select OptionId
    if ($optionIdsToMove -ne $null)
    {
        optionDefMigration -optionIdsToMove $optionIdsToMove.OptionId -sourceDhcpServerName $sourceDhcpServerName -DestinationDhcpServer $partnerDhcpServer
    }
    #endregion 

    #region scope migration
    Write-Output "--- Scope Migration ---"
    foreach ($scope in $sourceServerScopes)
    {
        if (Get-DhcpServerv4Scope -ScopeId $scope.ScopeId -ComputerName $DestinationDhcpServer -ErrorAction SilentlyContinue)
        {
            Write-Output "Scope $($scope.ScopeId);$($scope.Name) already exists on $($DestinationDhcpServer)."
        }
        else
        {
            Write-Output "Adding scope $($scope.ScopeId);$($scope.Name) to $($DestinationDhcpServer)..."
            $scopeSplat = @{
                Name = $scope.Name
                StartRange = $scope.StartRange
                EndRange = $scope.EndRange
                LeaseDuration = $scope.LeaseDuration
                SubnetMask = $scope.SubnetMask
                Description = $scope.Subscription
                ComputerName = $DestinationDhcpServer
            }
            try {
                Add-DhcpServerv4Scope @scopeSplat -State InActive -Verbose
            }
            catch {
                Write-Host -ForegroundColor Red "ERROR: Failed to add scope $($scope.ScopeId) to $($DestinationDhcpServer)."
                Write-Output "--- Exception ---"
                Write-Host -ForegroundColor Red $Error[0].Exception
                Write-Output "--- Exception ---"
            }
            $scopeOptions = Get-DhcpServerv4OptionValue -ScopeId $scope.ScopeId -ComputerName $sourceDhcpServerName
            Write-Output "--- Scope Options --- "
            foreach ($option in $scopeOptions)
            {
                Write-Output "Adding option value for $($option.OptionId) $($option.Name) to $($DestinationDhcpServer)..."
                switch -Exact ($option.OptionId) {
                    3 { 
                        $routerSplat = @{
                            ScopeId = $scope.ScopeId
                            Router = $option.Value
                            ComputerName = $DestinationDhcpServer
                        }
                        try {
                            Set-DhcpServerv4OptionValue @routerSplat -Verbose
                        }
                        catch {
                            Write-Host -ForegroundColor Red "ERROR: Failed to set option $($option.OptionId) to $($scope.ScopeId) on $($DestinationDhcpServer)."
                            Write-Output "--- Exception ---"
                            Write-Host -ForegroundColor Red $Error[0].Exception
                            Write-Output "--- Exception ---"
                        }
                    }
                    6 { 
                        $dnsServersSplat = @{
                            ScopeId = $scope.ScopeId
                            DnsServer = $option.Value
                            ComputerName = $DestinationDhcpServer
                        }
                        try {
                            Set-DhcpServerv4OptionValue @dnsServersSplat -Verbose
                        }
                        catch {
                            Write-Host -ForegroundColor Red "ERROR: Failed to set option $($option.OptionId) to $($scope.ScopeId) on $($DestinationDhcpServer)."
                            Write-Output "--- Exception ---"
                            Write-Host -ForegroundColor Red $Error[0].Exception
                            Write-Output "--- Exception ---"
                        }
                    }
                    15 { 
                        Write-Output "Option 15 DNS Domain is a server option set to vcaantechc.com"
                    }
                    Default {
                        $customOptionSplat = @{
                            ScopeId = $scope.ScopeId
                            OptionId = $option.OptionId
                            Value = $option.Value
                            ComputerName = $DestinationDhcpServer
                        }
                        try {
                            Set-DhcpServerv4OptionValue @customOptionSplat -Verbose
                        }
                        catch {
                            Write-Host -ForegroundColor Red "ERROR: Failed to set option $($option.OptionId) to $($scope.ScopeId) on $($DestinationDhcpServer)."
                            Write-Output "--- Exception ---"
                            Write-Host -ForegroundColor Red $Error[0].Exception
                            Write-Output "--- Exception ---"
                        }
                    }
                }
            }
            #region server option value migration
            Write-Output "Checking if any server options need to be migrated to the scope..."
            foreach ($serverOption in $sourceServerOptions)
            {
                switch -Exact ($serverOption.OptionId) {
                    6 { 
                        Write-Output "Migrating DNS Servers from Server Option to Scope Option..."
                        $dnsServersSplat = @{
                            ScopeId = $scope.ScopeId
                            DnsServer = $serverOption.Value
                            ComputerName = $DestinationDhcpServer
                        }
                        try {
                            Set-DhcpServerv4OptionValue @dnsServersSplat -Verbose
                        }
                        catch {
                            Write-Host -ForegroundColor Red "ERROR: Failed to set option $($serverOption.OptionId) to $($scope.ScopeId) on $($DestinationDhcpServer)."
                            Write-Output "--- Exception ---"
                            Write-Host -ForegroundColor Red $Error[0].Exception
                            Write-Output "--- Exception ---"
                        }
                    }
                    128 { 
                        Write-Output "Migrating Option 128 VlanPortId from Server Option to Scope Option..."
                        $vlanPortIdSplat = @{
                            ScopeId = $scope.ScopeId
                            OptionId = $serverOption.OptionId
                            Value = $serverOption.Value
                            ComputerName = $DestinationDhcpServer
                        }
                        try {
                            Set-DhcpServerv4OptionValue @vlanPortIdSplat -Verbose
                        }
                        catch {
                            Write-Host -ForegroundColor Red "ERROR: Failed to set option $($serverOption.OptionId) to $($scope.ScopeId) on $($DestinationDhcpServer)."
                            Write-Output "--- Exception ---"
                            Write-Host -ForegroundColor Red $Error[0].Exception
                            Write-Output "--- Exception ---"
                        }
                    }
                    Default {}
                }
            }
            #endregion
            #region Scope Leases
            $scopeLeases = Get-DhcpServerv4Lease -ScopeId $scope.ScopeId -ComputerName $sourceDhcpServerName
            Write-Output "--- Scope Leases --- "
            foreach ($lease in $scopeLeases)
            {
                Write-Output "Adding lease for $($lease.HostName) to $($DestinationDhcpServer)..."
                $leaseSplat = @{
                    ScopeId = $lease.ScopeId
                    IPAddress = $lease.IPAddress
                    ClientId = $lease.ClientId
                    HostName = $lease.HostName
                    ComputerName = $DestinationDhcpServer
                }
                try {
                    Add-DhcpServerv4Lease @leaseSplat -Verbose
                }
                catch {
                    Write-Host -ForegroundColor Red "ERROR: Failed to add lease for $($lease.HostName) to $($DestinationDhcpServer)."
                    Write-Output "--- Exception ---"
                    Write-Host -ForegroundColor Red $Error[0].Exception
                    Write-Output "--- Exception ---"
                }
            }
            #endregion
            #region scope reservations
            $scopeReservations = Get-DhcpServerv4Reservation -ScopeId $scope.ScopeID -ComputerName $sourceDhcpServerName
            Write-Output "--- Scope Reservations --- "
            foreach ($reservation in $scopeReservations)
            {
                Write-Output "Adding reservation for $($reservation.Name) to $($DestinationDhcpServer)..."
                $reservationSplat = @{
                    ScopeId = $reservation.ScopeId
                    IPAddress = $reservation.IPAddress
                    ClientId = $reservation.ClientId
                    Name = $reservation.Name
                    ComputerName = $DestinationDhcpServer
                }
                try {
                    Add-DhcpServerv4Reservation @reservationSplat -Verbose
                }
                catch {
                    Write-Host -ForegroundColor Red "ERROR: Failed to add reservation for $($reservation.Name) to $($DestinationDhcpServer)."
                    Write-Output "--- Exception ---"
                    Write-Host -ForegroundColor Red $Error[0].Exception
                    Write-Output "--- Exception ---"
                }
            }
            #endregion
            #region scope exclusions
            $scopeExclusions = Get-DhcpServerv4ExclusionRange -ScopeId $scope.ScopeID -ComputerName $sourceDhcpServerName
            Write-Output "--- Scope Exclusions ---"
            foreach ($exclusion in $scopeExclusions)
            {
                Write-Output "Adding exclusion range $($exclusion.StartRange)-$($exclusion.EndRange) for $($scope.ScopeID) to $($DestinationDhcpServer)."
                $exclusionSplat = @{
                    ScopeId = $exclusion.ScopeId
                    StartRange = $exclusion.StartRange
                    EndRange = $exclusion.EndRange
                    ComputerName = $DestinationDhcpServer
                    Confirm = $false
                }
                try {
                    Add-DhcpServerv4ExclusionRange @exclusionSplat -Verbose
                }
                catch {
                    Write-Host -ForegroundColor Red "ERROR: Failed to add exclusion range for $($exclusion.StartRange)-$($exclusion.EndRange) for $($scope.ScopeID) to $($DestinationDhcpServer)."
                    Write-Output "--- Exception ---"
                    Write-Host -ForegroundColor Red $Error[0].Exception
                    Write-Output "--- Exception ---"
                }
            }
            #endregion
        }
    }
}

#endregion

END
{
    #region ssh command for ansible
    Write-Output "Ready to configure ip helpers on switch..."
    Write-Output "Running the Ansible playbook to update the IP helper addresses..."

    ### This currently relies on the branch being used to be Task_159_ios_automation
    ### Change branch manually on repo directory on phazdevagt2 to use another working branch
    ### Don't use master
    ssh $ansibleProxyHostname "cd ~/ScriptExamples/Ansible/iOSSwitch/ip_helper && git pull && ansible-playbook -i ./hosts/$($BranchOfficeID).yml site.yml"
    #endregion
    #region enable scope
    $response = Read-Host -Prompt "Was the Ansible job successful? (y/n)"
    if ($response -like "y*")
    {
        foreach ($scope in $sourceServerScopes)
        {
        
            Write-Output "Enabling $($scope.ScopeId) on $($DestinationDhcpServer)..."
            try {
                Set-DhcpServerv4Scope -ScopeId $scope.ScopeId -State Active -ComputerName $DestinationDhcpServer -Verbose -ErrorAction SilentlyContinue
            }
            catch {
                Write-Host -ForegroundColor Red "ERROR: Failed to enable scope $($scope.ScopeId) to $($DestinationDhcpServer)."
                Write-Output "--- Exception ---"
                Write-Host -ForegroundColor Red $Error[0].Exception
                Write-Output "--- Exception ---"
            }
            Write-Output "Disabling $($scope.ScopeId) on $($sourceDhcpServerName)..."
            try {
                Set-DhcpServerv4Scope -ScopeId $scope.ScopeId -State InActive -ComputerName $sourceDhcpServerName -Verbose -ErrorAction SilentlyContinue
            }
            catch {
                Write-Host -ForegroundColor Red "ERROR: Failed to enable scope $($scope.ScopeId) to $($sourceDhcpServerName)."
                Write-Output "--- Exception ---"
                Write-Host -ForegroundColor Red $Error[0].Exception
                Write-Output "--- Exception ---"
            }
        }
        Write-Output "Finished migrating scopes from $($sourceDhcpServerName) to $($DestinationDhcpServer)."
    }
    elseif ($response -like "n*") 
    {
        Write-Output "Rerun this script with the same parameters once the failure reason has been remediated." 

    }
    Push-Location $StartingPath
    #endregion
}