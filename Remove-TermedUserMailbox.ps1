param(
    [int]$Count = 10,
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [string]$TermedOU,
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [string]$ExportPath
)

if (!(Get-Command Get-Mailbox))
{
    if (Test-Path -Path "C:\Program Files\Microsoft\Exchange Server\V15") 
    {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
    }
    else 
    {
        Write-Output "Connect to Exchange before running this script."
        break    
    }
}

#### Mailbox Export Prep ####
Start-Transcript
$termedMailboxes = Get-Mailbox -OrganizationalUnit $TermedOU -ResultSize Unlimited | Where-Object {(($_.LitigationHoldEnabled -eq $false) -and ($_.InPlaceHolds.Count -eq 0))}
Write-Output "Getting mailboxes to term..."
$termedMailboxes = $termedMailboxes | Get-MailboxStatistics | Where-Object {($_.LastLogonTime -LT (Get-Date).AddDays(-90))} 
$termedMailboxes = $termedMailboxes | select -First $Count
Write-Output "Mailboxes to terminate are:"
Write-Output ""
$termedMailboxes
Write-Output "Termed mailboxes will be exported to $($ExportPath)"
#### Mailbox Export Request Creation ####
foreach ($termedMailbox in $termedMailboxes)
{
    [string]$MailboxGuid = $termedMailbox.MailboxGuid
    $termedmailbox = Get-Mailbox -Identity $MailboxGuid
    if (!(Test-Path -Path ("$($ExportPath)"+$termedmailbox.SamAccountName+"\")))
    {
        New-Item -Path $ExportPath -Name $termedmailbox.SamAccountName -Type Directory #Create folder for mailbox
    }
    If ($termedmailbox.ArchiveState -eq "None") #Check if the mailbox has an archive
    {
        $mailboxFilePath = $ExportPath + $termedmailbox.SamAccountName + "\" + $termedmailbox.SamAccountName + ".pst" #Set the mailbox filename and path
        New-MailboxExportRequest -Mailbox $termedmailbox.SamAccountName -FilePath $mailboxFilePath -Name ($termedmailbox.SamAccountName + "_mailboxExport") -BadItemLimit 1000 -Verbose #Create the new mailbox export request for the mailbox
    }

    If ($termedmailbox.ArchiveState -ne "None") #Check if the mailbox has an archive
    {
        $archiveFilePath = $ExportPath + $termedmailbox.SamAccountName + "\" + $termedmailbox.SamAccountName + "_archive.pst" #Set the archive filename and path
        New-MailboxExportRequest -Mailbox $termedmailbox.SamAccountName -IsArchive -FilePath $archivefilepath -Name ($termedmailbox.SamAccountName + "_archiveExport") -BadItemLimit 1000 -Verbose #Create the new mailbox export request for the archive
        $mailboxFilePath = $ExportPath + $termedmailbox.SamAccountName + "\" + $termedmailbox.SamAccountName + ".pst" #Set the mailbox filename and path
        New-MailboxExportRequest -Mailbox $termedmailbox.SamAccountName -FilePath $mailboxFilePath -Name ($termedmailbox.SamAccountName + "_mailboxExport") -BadItemLimit 1000 -Verbose #Create the new mailbox export request for the mailbox
    }
}
#### Mailbox Cleanup ####
foreach ($termedMailbox in $termedMailboxes)
{
    [string]$MailboxGuid = $termedMailbox.MailboxGuid
    $termedmailbox = Get-Mailbox -Identity $MailboxGuid

    If ($termedmailbox.ArchiveState -eq "None") #Check if the mailbox has an archive
    {
        $FailedAlert = $null
        Do 
        {
            $mailboxExport = Get-MailboxExportRequest -Name ($termedmailbox.SamAccountName + "_mailboxExport") #Get information on the export request
            If (($mailboxExport.Status -eq "Failed") -and ($FailedAlert -eq $null))
            {
                Write-Output "$($mailboxExport.Name) has failed."
                $FailedAlert = 'Alerted'
                $FailureReason = (Get-MailboxExportRequestStatistics -Identity $mailboxExport).FailureType
                if ($FailureReason -eq 'TooManyMissingItemsPermanentException')
                {
                    Set-MailboxExportRequest -Identity $mailboxExport -BadItemLimit 5000
                    Resume-MailboxExportRequest -Identity $mailboxExport
                }
            }
            Start-Sleep -Seconds 15
        } while ($mailboxExport.Status -ne "Completed") #This will loop until the status of the export is completed       
        If ($mailboxExport.Status -eq "Completed") #Check if export request was completed
        {
            Disable-Mailbox -Identity $termedmailbox.Identity -Confirm:$false -Verbose #If completed remove the mailbox
            Remove-MailboxExportRequest -Identity $mailboxExport.Identity -Confirm:$false -Verbose
        }
    }

    If ($termedmailbox.ArchiveState -ne "None") #Check if the mailbox has an archive
    {
        Do 
        {
            $mailboxExport = Get-MailboxExportRequest -Name ($termedmailbox.SamAccountName + "_mailboxExport") #Get information on the export request
            $archiveExport = Get-MailboxExportRequest -Name ($termedmailbox.SamAccountName + "_archiveExport") #Get information on the archive export request
            Start-Sleep -Seconds 15
        } while (($mailboxExport.Status -ne "Completed") -and ($archiveExport.Status -ne "Completed")) #This will loop until the status of the mailbox and archive exports are completed
        If (($mailboxExport.Status -eq "Failed") -or ($archiveExport.Status -eq "Failed")) #Check if either export failed.   
        {
            Write-Output "$($mailboxExport.Name) has failed."
            Write-Output "$($archiveExport.Name) has failed."
        }
        If (($mailboxExport.Status -eq "Completed") -and ($archiveExport.Status -eq "Completed")) #Check if both export requests were completed
        {
            Disable-Mailbox -Identity $termedmailbox.Identity -Confirm:$false -Verbose #If completed remove the mailbox
            Remove-MailboxExportRequest -Identity $mailboxExport.Identity -Confirm:$false -Verbose
            Remove-MailboxExportRequest -Identity $archiveExport.Identity -Confirm:$false -Verbose
        }
    } 
}

Stop-Transcript