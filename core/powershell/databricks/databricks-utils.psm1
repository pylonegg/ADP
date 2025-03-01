#=============================================================================
# Author: Chi Adiukwu
# Initial Creation: 28/01/2025 
# LastUpdated: 29/01/2025
# Description: Powershell module for Databricks deployment
#=====================================|=======================================


# ----------------------------------------- #
# Install and configure databriks CLI
# ----------------------------------------- #
function Install-ConfigureCLI {
    param (
        [string]$DatabricksHost,
        [string]$DatabricksToken
    )

    # Install Databricks CLI
    Write-Host "Installing Databricks CLI..."
    Invoke-Expression "curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh"

    # Configure Databricks CLI
    Write-Host "Configuring Databricks CLI..."
    $databricksConfig = "$DatabricksHost`n$DatabricksToken"

    $databricksConfig | databricks configure --token
    Write-Host "Databricks CLI configured successfully!"
}

# ----------------------------------------- #
# Deploy Databricks bundle
# ----------------------------------------- #
function Deploy-DatabricksBundle {
    param (
        [string]$Environment
    )

   Write-Host "`n======================== DEPLOYING DATABRICKS BUNDLE! ========================"
    # Validate Databricks bundle
    databricks bundle validate -t $Environment
    Write-Host "$Environment databricks bundle validated!"

    # Deploy Databricks bundle
    databricks bundle deploy -t $Environment
    Write-Host "databricks bundle deployed successfully to $Environment!"
}

# ----------------------------------------- #
# Connect to Databricks
# ----------------------------------------- #
function Add-MetastoreToWorkspace {
    param(
        [String]$WorkspaceId,
        [String]$MetastoreId
    )

    Write-Host "Hello World"
    # databricks metastores assign $(WorkspaceId) $(MetastoreId) system
    # Write-Host "Metastore added to workspace successfully!"
}

# ----------------------------------------- #
# Install ClusterLibraries
# ----------------------------------------- #
function Get-ClusterIdByName {
    param(
        [String]$ClusterName,
        [string]$Environment
    )

    $clusters = databricks clusters list -t $Environment -o json | ConvertFrom-Json | Where-Object { $_.cluster_name -eq $ClusterName }
    if (-not $clusters){
        Write-Error "Cluster `"$ClusterName`" does not exist!"
    }

    $ClusterId = $clusters[0].cluster_id
    Write-Host "Cluster Id for $ClusterName is: $ClusterId"
    return $ClusterId
}

# ----------------------------------------- #
# Install ClusterLibraries
# ----------------------------------------- #
function Install-ClusterLibraries {
    param(
        [String]$ClusterName,
        [String]$RequirementsFilePath,
        [string]$Environment
    )

    Write-Host "`n==================== ADDING requirements.txt TO CLUSTER! ====================="
    Write-Host "Getting Cluster Id for $ClusterName"
    $ClusterId = Get-ClusterIdByName -ClusterName $ClusterName -Environment $Environment

    # Create the JSON payload   
    $jsonPayload = @"
{
    "cluster_id": "$clusterId",
    "libraries": [{"requirements": "$RequirementsFilePath"}]
}
"@
    databricks libraries install -t $Environment --json $jsonPayload
    Write-Host "Requirements path $RequirementsFilePath successfully added to `"$ClusterName`" library"
}

# ----------------------------------------- #
# Create a Secret Scope
# ----------------------------------------- #
function Add-AzureKeyVaultBackedScope {
    param(
        [string]$ScopeName,
        [string]$KeyVaultName,
        [string]$ResourceID
    )

    Write-Host "`n=============== ADDING AZURE KEYVAULT BACKED SCOPE TO CLUSTER! ==============="
    # Check if the scope already exists
    $ExistingScopes = databricks secrets list-scopes -o json | ConvertFrom-Json | Where-Object { $_.name -eq $ScopeName }

    if (-not $ExistingScopes) {
        # Create the secret scope
        Write-Host "Creating secret scope: $ScopeName..."
        $KeyVaultUri = "https://$KeyVaultName.vault.azure.net/"
        $SecretScope = '{"scope":"'+$ScopeName+'","scope_backend_type":"AZURE_KEYVAULT","backend_azure_keyvault":{"resource_id":"'+$ResourceID+'","dns_name":"'+$KeyVaultUri+'"}}'
        databricks secrets create-scope --json $SecretScope
        Write-Host "$ScopeName - $KeyVaultName has been successfully added to databricks"
    }
    else {
        Write-Host "Secret scope '$ScopeName' already exists. Skipping creation."
        return
    }
}

# ----------------------------------------- #
# Check and Add or Update a Secret in Scope
# ----------------------------------------- #
function Add-OrUpdateSecret {
    param(
        [string]$ScopeName,
        [string]$KeyName,
        [string]$KeyValue
    )

    Write-Host "`n================= ADDING DATABRICKS BACKED SCOPE TO CLUSTER! ================="
    $ExistingScopes = databricks secrets list-scopes -o json | ConvertFrom-Json | Where-Object { $_.name -eq $ScopeName }
    if (-not $ExistingScopes.name) {
        Write-Host "Scope does not exist, creating `"$ScopeName`""
        databricks secrets create-scope $ScopeName
    }

    Write-Host "Adding/Updating secret `"$KeyName`""
    $Secret = '{"scope":"' + $ScopeName + '","key":"' + $KeyName + '","string_value":"' + $KeyValue + '"}'
    databricks secrets put-secret --json $Secret
    Write-Host "`"$KeyName`" has been successfully added to databricks scope `"$ScopeName`""
}