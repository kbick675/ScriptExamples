#!/usr/bin/env bash

isAzLoggedIn=$(az account list)
if [ "$isAzLoggedIn" == "[]" ]; then
    az login
else
    echo $isAzLoggedIn | jq
fi

arminfo=$(cat ./ARMInformation.json)
subName=$(echo $arminfo | jq .subscriptionName)
rgName=$(echo $arminfo | jq .resourceGroup)
spName=$(echo $arminfo | jq .spDisplayName)
kvName=$(echo $arminfo | jq .keyVaultName)

subId=$(az account show --subscription $subName | jq .id)
az account set -s $subId

tenantId=$(az account show --subscription $subName | jq .tenantId)
appId=$(az ad sp show --id $servicePrincipal --subscription $subId | jq .appId )
secretvalue=$(az keyvault secret show --name $spName  --vault-name $kvName | jq .value)

## Azure Automation is not currently supported in azure cli. 
## And only partially supported in Terraform as there are currently no data sources, only resources
#azureAutomationAccount=
#automationRegistrationEndpoint=
#automationRegistrationKey=

export ARM_SUBSCRIPTION_ID=$subId
export ARM_CLIENT_ID=$appId
export ARM_CLIENT_SECRET=$secretvalue
export ARM_TENANT_ID=$tenantId
## export TF_VAR_DSC_ENDPOINT=
## export TF_VAR_DSC_KEY=