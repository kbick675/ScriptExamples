Push-Location (Split-Path $script:MyInvocation.MyCommand.Path)

if ([string]::IsNullOrEmpty($(Get-AzContext).Account))
{
    Connect-AzAccount
}

$ARMInfo = Get-Content .\ARMInformation.json | ConvertFrom-Json

$azResourceGroup = Get-AzResourceGroup -Name $ARMInfo.resourceGroup
$azSubscription = (Get-AzSubscription -SubscriptionName $ARMInfo.subscriptionName)

Set-AzContext -SubscriptionId $azSubId

$appId = (Get-AzADServicePrincipal -ServicePrincipalName $ARMInfo.spDisplayName).ApplicationId

$Vault = Get-AzKeyVault -VaultName $ARMInfo.keyVaultName -ResourceGroupName $azResourceGroup.ResourceGroupName
$Secret = Get-AzKeyVaultSecret -VaultName $Vault.VaultName -Name TerraformDev
$AzureAutomation = Get-AzAutomationAccount -ResourceGroupName $azResourceGroup.ResourceGroupName
$AzureAutomationRegistration = $AzureAutomation | Get-AzAutomationRegistrationInfo

$ENV:ARM_SUBSCRIPTION_ID=$azSubscription.Id
$ENV:ARM_CLIENT_ID=$appId
$ENV:ARM_CLIENT_SECRET=$Secret.SecretValueText
$ENV:ARM_TENANT_ID=$azSubscription.TenantId
$ENV:TF_VAR_DSC_ENDPOINT=$AzureAutomationRegistration.Endpoint
$ENV:TF_VAR_DSC_KEY=$AzureAutomationRegistration.PrimaryKey