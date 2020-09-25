param (
    [Parameter(Mandatory = $true)]
    [ValidateScript( {
            if ($_ | Test-Path) {
                return $true
            }
            elseif (!($_ | Test-Path)) {
                throw "Configuration file does not exist or path is incorrect."
            }
        })]
    [System.IO.FileInfo]
    $PathToConfigurationFile
)

Configuration Server_Prereqs
{
    Import-DscResource -ModuleName cChoco -ModuleVersion 2.4.0.0
    Import-DscResource -ModuleName Carbon -ModuleVersion 2.9.2

    Node $AllNodes.Where{ $_.Role -eq 'nstemplate' }.NodeName
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }
        #region IIS
        $IISFeatures = @(
            "Web-WebServer",
            "Web-Common-Http",
            "Web-Default-Doc",
            "Web-Dir-Browsing",
            "Web-Http-Errors",
            "Web-Static-Content",
            "Web-Http-Redirect",
            "Web-DAV-Publishing",
            "Web-Health",
            "Web-Http-Logging",
            "Web-Custom-Logging",
            "Web-Log-Libraries",
            "Web-ODBC-Logging",
            "Web-Request-Monitor",
            "Web-Http-Tracing",
            "Web-Performance",
            "Web-Stat-Compression",
            "Web-Dyn-Compression",
            "Web-Security",
            "Web-Filtering",
            "Web-Basic-Auth",
            "Web-CertProvider",
            "Web-Client-Auth",
            "Web-Digest-Auth",
            "Web-Cert-Auth",
            "Web-IP-Security",
            "Web-Url-Auth",
            "Web-Windows-Auth",
            "Web-App-Dev",
            "Web-Net-Ext",
            "Web-Net-Ext45",
            "Web-AppInit",
            "Web-ASP",
            "Web-Asp-Net",
            "Web-Asp-Net45",
            "Web-CGI",
            "Web-ISAPI-Ext",
            "Web-ISAPI-Filter",
            "Web-Includes",
            "Web-WebSockets",
            "Web-Mgmt-Tools",
            "Web-Mgmt-Console",
            "Web-Mgmt-Compat",
            "Web-Metabase",
            "Web-Lgcy-Mgmt-Console",
            "Web-Lgcy-Scripting",
            "Web-WMI",
            "Web-Scripting-Tools",
            "Web-Mgmt-Service",
            "Web-WHC"
        )
        WindowsFeature IIS {
            Ensure = "Present"
            Name   = "Web-Server"            
        }
        foreach ($IISFeature in $IISFeatures) {
            WindowsFeature "IIS-$($IISFeature)" {
                Ensure    = "Present"
                Name      = "$($IISFeature)"
                DependsOn = "[WindowsFeature]IIS"
            }
        }

        WindowsFeature dotNet35 {
            Ensure               = "Present" 
            Name                 = "NET-Framework-Features"
            IncludeAllSubFeature = $true 
            DependsOn            = "[WindowsFeature]IIS"
            Source               = "\\domain.com\folders\Apps\install_media\Microsoft\Windows Server 2019\sources\sxs"
        }

        WindowsFeature dotNet45 {
            Ensure               = "Present"
            Name                 = "NET-Framework-45-Features"
            DependsOn            = "[WindowsFeature]IIS"
            IncludeAllSubFeature = $true  
        }

        WindowsFeature dotNet45HTTPActivation {
            Ensure    = "Present"
            Name      = "NET-WCF-HTTP-Activation45"
            DependsOn = "[WindowsFeature]dotNet45"
        }

        $InetPubRoot = "C:\Inetpub"
        $InetPubLog = "C:\Inetpub\Log"
        $InetPubWWWRoot = "C:\Inetpub\WWWRoot"
        $ServiceSiteRoot = "C:\Inetpub\ServiceRoot"
        $APISiteRoot = "C:\Inetpub\APIRoot"
        $WebAPIRoot = "C:\Inetpub\APIRoot\WebAPI"
        $ServiceRoot = "C:\Inetpub\ServiceRoot\Service"
        $IISDirs = @(
            $InetPubRoot,
            $InetPubLog,
            $InetPubWWWRoot,
            $ServiceSiteRoot,
            $APISiteRoot,
            $WebAPIRoot,
            $ServiceRoot,
            "C:\Inetpub\temp",
            "C:\Inetpub\temp\apppools",
            "C:\scripts\",
            "C:\scripts\iisPerformancesettings\"
        )
        foreach ($IISDir in $IISDirs) {
            File "IISDir-$($IISDir)" {
                Ensure          = "Present"
                Type            = "Directory"
                DestinationPath = "$($IISDir)"
            }
        }
        File "randomtxtfile" {
            Ensure          = "Present"
            Type            = "file"
            DestinationPath = "C:\scripts\iisPerformancesettings\log1-1.txt"
            Contents        = "" 
        }
        #endregion
        #region RDS
        WindowsFeature Remote-Desktop-Services { 
            Ensure = "Present" 
            Name   = "Remote-Desktop-Services" 
        }
        WindowsFeature RDS-RD-Server { 
            Ensure    = "Present" 
            Name      = "RDS-RD-Server" 
            DependsOn = "[WindowsFeature]Remote-Desktop-Services"
        }
        WindowsFeature RSAT-RDS-Tools { 
            Ensure = "Present" 
            Name   = "RSAT-RDS-Tools" 
        }
        WindowsFeature RSAT-RDS-Licensing-Diagnosis-UI {
            Ensure    = "Present"
            Name      = "RSAT-RDS-Licensing-Diagnosis-UI"
            DependsOn = "[WindowsFeature]RSAT-RDS-Tools"
        }
        #endregion
        #region Folders
        File temp {
            Ensure          = 'Present'
            DestinationPath = "C:\temp"
            Type            = "Directory"
        }
        File swsetup {
            Ensure          = 'Present'
            DestinationPath = "C:\swsetup"
            Type            = "Directory"
        }
        File scripts {
            Ensure          = 'Present'
            DestinationPath = "C:\scripts"
            Type            = "Directory"
        }
        #endregion
        #region Chololatey installs
        cChocoInstaller InstallChoco {
            InstallDir = "C:\ProgramData\chocolatey"
        }
        cChocoPackageInstaller webpi {
            Name      = "webpi"
            DependsOn = "[cChocoInstaller]InstallChoco"
        }
        cChocoPackageInstaller webdeploy {
            Name      = "webdeploy"
            DependsOn = @("[cChocoInstaller]InstallChoco", "[cChocoPackageInstaller]webpi")
        }
        #endregion Chocolatey installs

        #region Adobe Reader DC
        File AdobeReaderDC {
            Ensure          = "Present"
            Type            = "Directory"
            SourcePath      = "\\domain.com\folders\Apps\install_media\Adobe\Acrobat Reader DC\MSI"
            DestinationPath = "C:\swsetup\AdobeReader"
            Recurse         = $true
            MatchSource     = $true
            Checksum        = "SHA-256"
        }
        Package AdobeReaderDC {
            Ensure    = 'Present'
            Path      = "C:\swsetup\AdobeReader\AcroRead.msi"
            Name      = "Adobe Acrobat Reader DC"
            ProductId = "AC76BA86-7AD7-1033-7B44-AC0F074E4100"
            Arguments = "DISABLEDESKTOPSHORTCUT=1 /qn"
            DependsOn = "[File]AdobeReaderDC"
        }
        Registry AdobeReaderDCPolicyFeatureLockdown {
            Ensure    = "Present" 
            Key       = "HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown"
            ValueName = "bProtectedMode"
            ValueData = "0"
            ValueType = "DWord"
            Force     = $true
            DependsOn = "[Package]AdobeReaderDC"
        }
        Registry AdobeReaderDCWOW64PolicyFeatureLockdown {
            Ensure    = "Present" 
            Key       = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown"
            ValueName = "bProtectedMode"
            ValueData = "0"
            ValueType = "DWord"
            Force     = $true
            DependsOn = "[Package]AdobeReaderDC"
        }
        #endregion 

        #region 7zip 
        ## could also be handled by choco
        ## Could use SCCM as well, but this is much newer version than currently deployed
        File 7zip {
            Ensure          = "Present"
            Type            = "file"
            SourcePath      = "\\domain.com\folders\Apps\install_media\7zip\x64\19.00\7z1900-x64.msi"
            DestinationPath = "C:\swsetup\7z1900-x64.msi"
            MatchSource     = $true
            Checksum        = "SHA-256"  
        }
        Package 7zip {
            Ensure    = "Present"
            Path      = "C:\swsetup\7z1900-x64.msi"
            Name      = "7-Zip 19.00 (x64 edition)"
            ProductId = "23170F69-40C1-2702-1900-000001000000"
            Arguments = "/q"
            DependsOn = "[File]7zip"
        }
        #endregion 7zip

        #region Chrome Enterprise is not available via choco. 
        ## Can use SCCM as well
        File ChromeEnterprise {
            Ensure          = "Present"
            Type            = "File"
            SourcePath      = "\\domain.com\folders\Apps\install_media\Google\Chrome\Enterprise\Installers\GoogleChromeStandaloneEnterprise64.msi"
            DestinationPath = "C:\swsetup\GoogleChromeStandaloneEnterprise64.msi"
            MatchSource     = $true
            Checksum        = "SHA-256"
            Force           = $true
        }
        Package ChromeEnterprise {
            Ensure    = "Present"
            Path      = "C:\swsetup\GoogleChromeStandaloneEnterprise64.msi"
            Name      = "Google Chrome"
            ProductId = "5CA26E14-02B6-3987-AF74-B14B8E1512E5"
            Arguments = "/qn"
            DependsOn = "[File]ChromeEnterprise"
        }
        #endregion Chrome Enterprise
        
        #region Zebra printer drivers\
        File ZebraPrintDrivers {
            Ensure          = "Present"
            Type            = "Directory"
            SourcePath      = "\\domain.com\folders\Apps\install_media\ZebraPrintDrivers\ZD5-1-16-6924\ZBRN\"
            DestinationPath = "C:\swsetup\ZBRN\"
            MatchSource     = $true
            Recurse         = $true
            Checksum        = "SHA-256"
        }
        Script ZebraPrintDrivers {
            GetScript  = {
                if (Get-PrinterDriver -Name ZDesigner*) {
                    $Ensure = 'Present'
                }
                else {
                    $Ensure = 'Absent'
                }
                $result = @{
                    Ensure = $Ensure
                }
                return $result
            }
            TestScript = {
                $state = [scriptblock]::Create($GetScript).Invoke()
                if ($state.Ensure -eq 'Present') {
                    Write-Verbose -Message "Zebra ZDesigner drivers are installed. No action is required."
                    return $true
                }
                else {
                    return $false
                }
            }
            SetScript  = {
                $process = Start-Process -FilePath "pnputil.exe" -ArgumentList "/add-driver", "C:\swsetup\ZBRN\ZBRN.inf" -Wait -NoNewWindow -PassThru
                $exitcode = $process.ExitCode
                if ($exitcode -eq 0) {
                    Write-Verbose -Message "Zebra print drivers added to driver store."
                    Write-Verbose -Message "Adding printer drivers..."
                    Write-Verbose -Message "Adding driver for ZDesigner GK420d..."
                    Add-PrinterDriver -Name "ZDesigner GK420d"
                    Write-Verbose -Message "Adding driver for ZDesigner GX420d..."
                    Add-PrinterDriver -Name "ZDesigner GX420d"
                }
                else {
                    Write-Verbose -Message "pnputil exited with exitcode: $($exitcode)"
                }
            }
            DependsOn  = "[File]ZebraPrintDrivers"
        }
        Script RemoveMSXPSDocPrinter {
            GetScript  = {
                if (Get-Printer -Name "Microsoft XPS Document Writer" -ErrorAction SilentlyContinue) {
                    $Ensure = 'Present'
                }
                else {
                    $Ensure = 'Absent'
                }
                $result = @{
                    Ensure = $Ensure
                }
                return $result
            }
            TestScript = {
                $state = [scriptblock]::Create($GetScript).Invoke()
                if ($state.Ensure -eq 'Present') {
                    Write-Verbose -Message "Microsoft XPS Document Writer needs to be removed."
                    return $false
                }
                else {
                    return $true
                }
            }
            SetScript  = {
                Get-Printer -Name "Microsoft XPS Document Writer" | Remove-Printer
            }
        }
        Script RemoveSendToOnenote {
            GetScript  = {
                if (Get-Printer -Name "Send To OneNote 16" -ErrorAction SilentlyContinue) {
                    $Ensure = 'Present'
                }
                else {
                    $Ensure = 'Absent'
                }
                $result = @{
                    Ensure = $Ensure
                }
                return $result
            }
            TestScript = {
                $state = [scriptblock]::Create($GetScript).Invoke()
                if ($state.Ensure -eq 'Present') {
                    Write-Verbose -Message "Send To OneNote 16 needs to be removed."
                    return $false
                }
                else {
                    return $true
                }
            }
            SetScript  = {
                Get-Printer -Name "Send To OneNote 16" | Remove-Printer
            }
        }

        #region Risk and safety shortcut
        File RiskIncidentReportingLink {
            Ensure          = "Present"
            Type            = "File"
            SourcePath      = "\\domain.com\folders\Apps\install_media\RiskAndSafetyShortcut\Risk Incident Reporting.url"
            DestinationPath = "C:\Users\Public\Desktop\Risk Incident Reporting.url"
        }
        File RSReportingIcon {
            Ensure          = "Present"
            Type            = "File"
            SourcePath      = "\\domain.com\folders\Apps\install_media\RiskAndSafetyShortcut\RSReporting.ico"
            DestinationPath = "C:\Windows\System32\RSReporting.ico"
        }
        #endregio

        #region Printer Registry Perms
        Carbon_Permission printersRegistryPerm {
            Ensure     = 'Present'
            Path       = 'HKLM:\SYSTEM\ControlSet001\Control\Print\Printers'
            Identity   = 'BUILTIN\Users'
            Permission = 'FullControl'
            ApplyTo    = 'ContainerAndChildContainersAndChildLeaves'  
        }
        #endregion
    }
}

#region Manual Run
$startLocation = Get-Location

Push-Location (Split-Path $script:MyInvocation.MyCommand.Path)

$configData = Import-PowerShellDataFile $PathToConfigurationFile

if (Test-Path -Path C:\temp) {
    Server_Prereqs -ConfigurationData $configData -OutputPath C:\temp\Server_Prereqs
}
else {
    Write-Output "C:\temp doesn't exist. Creating..."
    try {
        New-Item -Path C:\temp
    }
    catch {
        Write-Output "Unable to create C:\temp. Exiting."
        Write-Output "$($Error[0].Exception)"
        Exit
    }
    if (Test-Path -Path C:\temp) {
        Write-Output "C:\temp was created. Continuing..."
        Server_Prereqs -ConfigurationData $configData -OutputPath c:\temp\Server_Prereqs
    }
}

[string[]]$Nodes = ($configData.AllNodes.where{ $_.Role -eq 'nstemplate' }).NodeName
Set-DscLocalConfigurationManager -Path C:\temp\Server_Prereqs -ComputerName $Nodes -Verbose
Start-DscConfiguration -Path C:\temp\Server_Prereqs -ComputerName $Nodes -Wait -Verbose -Force

Push-Location $startLocation
#endregion