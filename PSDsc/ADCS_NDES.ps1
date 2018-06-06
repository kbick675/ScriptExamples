param(
    [string]$NodeName,
    [switch]$Force
)

Configuration NewNdesServer
{
    param(
        [string]$NodeName,
        [pscredential]$DomainAdmin
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node $NodeName
    {
        $netcorefeatures = @(
            "NET-Framework-Features",
            "NET-Framework-Core",
            "NET-HTTP-Activation"
        )

        $net45features = @(
            "NET-Framework-45-Features",
            "NET-Framework-45-Core",
            "NET-Framework-45-ASPNET",
            "NET-WCF-Services45",
            "NET-WCF-HTTP-Activation45"
        )

        $requiredFeatures = @(
            "Web-Server",
            "Web-Mgmt-Tools",
            "Web-Mgmt-Console",
            "Web-Mgmt-Compat",
            "Web-Metabase",
            "Web-WMI",
            "Web-Mgmt-Service",
            "Web-WebServer",
            "Web-Common-Http",
            "Web-Default-Doc",
            "Web-Static-Content",
            "Web-Performance",
            "Web-Stat-Compression",
            "Web-Dyn-Compression",
            "Web-Security",
            "Web-Filtering",
            "Web-Windows-Auth",
            "Web-App-Dev",
            "Web-Net-Ext",
            "Web-Asp-Net",
            "Web-Net-Ext45",
            "Web-Asp-Net45"
            )

        LocalConfigurationManager 
        { 
            RebootNodeIfNeeded = $true
            CertificateID = '698743ED8C0284F8FD34A5112704BB42DE944509'
        }

        foreach ($netcorefeature in $netcorefeatures)
        {
            WindowsFeature "WindowsFeature-$netcorefeature"
            {
                Ensure = 'Present'
                Name   = $netcorefeature
                Source = "\\filer1\images\WIMImages\2016\setup\sources\sxs"
            }
        }
        GroupSet ndesgmsaGroupMembership
        {
            GroupName = @('Administrators','IIS_IUSRS')
            Ensure = 'Present'
            MembersToInclude = @("ndesgmsa$")
            Credential = $DomainAdmin
        }
        foreach ($net45feature in $net45features)
        {
            WindowsFeature "WindowsFeature-$net45feature"
            {
                Ensure = 'Present'
                Name   = $net45feature
            }
        }
        foreach ($feature in $requiredFeatures)
        {
            WindowsFeature "WindowsFeature-$feature"
            {
                Ensure = 'Present'
                Name   = $feature
            }
        }
        WindowsFeature "NDES"
        {
            Ensure = "Present"
            Name = "ADCS-Device-Enrollment"
        }
        Script "InstallNDES"
        {
            GetScript = {
                return @{
                    TestScript = $TestScript
                }
            }
            TestScript = {
                $InstallState = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\ADCS\NDES\" -Name ConfigurationStatus -ErrorAction SilentlyContinue
                if ($InstallState.ConfigurationStatus -eq 2) 
                {
                    Write-Verbose -Message "NDES is setup already."
                    return $true
                }
                elseif (($InstallState.ConfigurationStatus -eq 1) -or ($InstallState.ConfigurationStatus -eq 0))
                {
                    Write-Verbose -Message "NDES is not setup."
                    return $false
                }
            }
            SetScript = {
                $NDESName = $Using:NodeName
                Install-AdcsNetworkDeviceEnrollmentService -ApplicationPoolIdentity -SigningKeyLength 2048 -RAName "$($NDESName)-MSCEP-RA" -RAEmail "hostmasters@spacex.com" -RACompany "SpaceX" -RADepartment "IT" -RACity "Hawthorne" -RAState "CA" -RACountry "US" -EncryptionKeyLength 2048 -CAConfig "ht1-ca-iss1.spacex.corp\SpaceX Issuing CA"
            }
            PsDscRunAsCredential = $DomainAdmin
        }
        Registry "SinglePassword"
        {
            Ensure = "Present"
            Key = "HKLM:\SOFTWARE\Microsoft\Cryptography\MSCEP\UseSinglePassword"
            ValueName = "UseSinglePassword"
            ValueData = "1"
            ValueType = "Dword"
            DependsOn = "[Script]InstallNDES"
        }
        Registry "EncryptionTemplate"
        {
            Ensure = "Present"
            Key = "HKLM:\SOFTWARE\Microsoft\Cryptography\MSCEP"
            ValueName = "EncryptionTemplate"
            ValueData = "MobileDeviceScep"
            ValueType = "String"
            DependsOn = "[Script]InstallNDES"
        }
        Registry "GeneralPurposeTemplate"
        {
            Ensure = "Present"
            Key = "HKLM:\SOFTWARE\Microsoft\Cryptography\MSCEP"
            ValueName = "GeneralPurposeTemplate"
            ValueData = "MobileDeviceScep"
            ValueType = "String"
            DependsOn = "[Script]InstallNDES"
        }
        Registry "SignatureTemplate"
        {
            Ensure = "Present"
            Key = "HKLM:\SOFTWARE\Microsoft\Cryptography\MSCEP"
            ValueName = "SignatureTemplate"
            ValueData = "MobileDeviceScep"
            ValueType = "String"
            DependsOn = "[Script]InstallNDES"
        }
        Registry "MaxFieldLength"
        {
            Ensure = "Present"
            Key = "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters"
            ValueName = "MaxFieldLength"
            ValueData = "65534"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]WindowsFeature-Web-Server"
        }
        Registry "MaxRequestBytes"
        {
            Ensure = "Present"
            Key = "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters"
            ValueName = "MaxRequestBytes"
            ValueData = "65534"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]WindowsFeature-Web-Server"
        }
    }
}

$Config = @{
    AllNodes = @(
        @{
            NodeName = $NodeName
            PSDscAllowDomainUser = $true
            CertificateFile = "C:\pki\publickey.cer"
            Thumbprint = '698743ED8C0284F8FD34A5112704BB42DE944509'
            #Template = "MobileDeviceScep"
            #Template = "SpaceXWebServer"
        }
    )
}

$StartingLocation = Get-Location

Push-Location \\path\to\dsc\runpath

NewNdesServer -NodeName $NodeName -ConfigurationData $Config -DomainAdmin (Get-Credential) -OutputPath .\NewNdesServer\ 

if ($Force)
{
    Set-DscLocalConfigurationManager -ComputerName $NodeName -Force -verbose -path .\NewNdesServer\ 
    
    Start-DscConfiguration -ComputerName $NodeName -Force -verbose -path .\NewNdesServer\
}
else
{
    Set-DscLocalConfigurationManager -ComputerName $NodeName -verbose -path .\NewNdesServer\ 
    
    Start-DscConfiguration -ComputerName $NodeName -verbose -path .\NewNdesServer\
}

Push-Location $StartingLocation

## Set App Pool to run as ndesgmsa. 
## set app pool to load profile
## 