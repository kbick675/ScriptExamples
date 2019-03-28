Push-Location (Split-Path $script:MyInvocation.MyCommand.Path)

$ARMInfo = Get-Content .\ARMInformation.json | ConvertFrom-Json

if ([string]::IsNullOrEmpty($(Get-AzContext).Account))
{
    Connect-AzAccount
}

$AzureRmResourceGroup = Get-AzResourceGroup -Name 'au10507_storage_pmsdata_lab_wu'

$AzureRMSubId = "8d5640f7-de61-49be-a2e4-0a081f4f0d8f"
$KeyVaultName = "SecretVaultDev"

$Vault = Get-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $AzureRmResourceGroup.ResourceGroupName
$Secret = Get-AzKeyVaultSecret -VaultName $Vault.VaultName -Name TerraformDev
$AzureAutomation = Get-AzAutomationAccount -ResourceGroupName $AzureRmResourceGroup.ResourceGroupName
$AzureAutomationRegistration = $AzureAutomation | Get-AzAutomationRegistrationInfo

$ENV:ARM_SUBSCRIPTION_ID=$AzureRMSubId
$ENV:ARM_CLIENT_ID=$ARMInfo.appId
$ENV:ARM_CLIENT_SECRET=$Secret.SecretValueText
$ENV:ARM_TENANT_ID=$ARMInfo.tenant
$ENV:TF_VAR_DSC_ENDPOINT=$AzureAutomationRegistration.Endpoint
$ENV:TF_VAR_DSC_KEY=$AzureAutomationRegistration.PrimaryKey