param (
    [string]$NodeName
)

Configuration InstalldotNet471
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $NodeName
    {

        File dotnetfiles
        {
            Ensure = "Present"
            SourcePath = "\\path\to\packages\Installers\Microsoft\dotnet471offline\NDP471-KB4033342-x86-x64-AllOS-ENU.exe"
            DestinationPath = "C:\SetupBinaries\dotnet\NDP471-KB4033342-x86-x64-AllOS-ENU.exe"
            Type = "File"
            MatchSource = $true
        }
        Script InstalldotNet
        {
            GetScript = {
                Write-Verbose "[Get].net Release"
                return @{
                    Result = [string](Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' -Name Release).Release
                    }
            }
            SetScript = {
                #Write-Verbose "[Set].net installation"
                Invoke-Command -ScriptBlock {cmd.exe /c "C:\SetupBinaries\dotnet\NDP471-KB4033342-x86-x64-AllOS-ENU.exe /q"}
            }
            TestScript = {
                Write-Verbose "[Test].net Release"
                $result = $GetScript
                Write-Verbose "[Test].net Release is $($result)"
                if ($result -eq '461310')
                {
                    return $true
                }
                elseif ($result -ne '461310')
                {
                    return $false
                }
            }
            DependsOn = '[File]dotnetfiles'
        }
    }
}

$StartingLocation = Get-Location
Push-Location \\path\to\dsc\runpath
InstalldotNet471
Start-DscConfiguration -Path .\InstalldotNet471 -ComputerName $NodeName -Verbose
Push-Location $StartingLocation 