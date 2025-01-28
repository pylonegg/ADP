


param (
    [string]$DatabricksHost,
    [string]$DatabricksToken,
    [string]$Environment,
    [string]$ClusterName
)

Join-Path -Path $PSScriptRoot -ChildPath "../../core/powershell/DatabricksUtils.psm1" | Import-Module
# --------------------------------------------------------------------------------------------------
# Create a function in Core/Powershell/DatabricksUtils.psm1 and call it here!
# --------------------------------------------------------------------------------------------------

Install-ConfigureCLI -DatabricksHost $DatabricksHost -DatabricksToken -$DatabricksToken
#Assign-MetastoreToWorkspace -WorkspaceId "" -MetastoreId ""
cd src/azure.databricks
Deploy-DatabricksBundle -Environment $Environment
# Install-ClusterLibraries -ClusterName $ClusterName
Create-SecretScope -ScopeName "TestScope"`
 -BackendType "AZURE_KEYVAULT"`
 -KeyVaultUri "https://uksdev01akv.vault.azure.net/"`
 -ResourceID "/subscriptions/7ca63534-9872-46b6-8a96-a155c7f96e59/resourceGroups/uksdev01rg/providers/Microsoft.KeyVault/vaults/uksdev01akv"
 
 # Create Databricks backed secret
 Add-OrUpdateSecret -