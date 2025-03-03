# ---------------------------------------------------------------
# Author: Chi Adiukwu
# Initial Creation: 28/01/2025 
# LastUpdated: 29/01/2025
# Description: Calls Powershell module/functions (Databricks)
# ---------------------------------------------------------------

param (
    [string]$DatabricksHost,
    [string]$DatabricksToken,
    [string]$ClusterName,
    [string]$KeyVaultName,
    [string]$KeyVaultResourceID,
    [string]$ADLS_SPN
)

Join-Path -Path $PSScriptRoot -ChildPath "databricks-utils.psm1" | Import-Module

# --------------------------------------------------------------------------------------------------
# Create a function in core/powershell/databricks-utils.psm1 and call it here!
# --------------------------------------------------------------------------------------------------

# Replace databricks.yml variables
$replacementPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../src/azure.databricks/app/databricks.yml" 
Replace-Parameters -DatabricksHost $DatabricksHost -filePath $replacementPath

Install-ConfigureCLI -DatabricksHost $DatabricksHost -DatabricksToken -$DatabricksToken

#Assign-MetastoreToWorkspace -WorkspaceId "" -MetastoreId ""

# Change working directory to bundle root.
cd src/azure.databricks/app

# Deploy databricks bundle
Deploy-DatabricksBundle

# Add requirements.txt to 
Install-ClusterLibraries -ClusterName $ClusterName -RequirementsFilePath "/Workspace/Shared/dbx/files/config/requirements.txt"

# Create Keyvault backed Scope
Add-AzureKeyVaultBackedScope -ScopeName "scope-advdai-$Environment" -KeyVaultName $KeyVaultName -ResourceID $KeyVaultResourceID

# Add databricks backed scope and secrets
Add-OrUpdateSecret -ScopeName "BlobStorage" -KeyName "ADLS_SPN" -KeyValue $ADLS_SPN