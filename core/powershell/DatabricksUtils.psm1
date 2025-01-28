


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
    
    # Validate Databricks bundle
    databricks bundle validate -t $Environment
    Write-Host "databricks bundle validated successfully!"

    # Deploy Databricks bundle
    databricks bundle deploy -t $Environment
    Write-Host "databricks bundle deployed successfully!"  
}

# ----------------------------------------- #
# Connect to Databricks
# ----------------------------------------- #
function Assign-MetastoreToWorkspace {
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
        [String]$ClusterName
    )
    
    $clusters = databricks clusters list -o json | ConvertFrom-Json | Where-Object { $_.cluster_name -eq $ClusterName }
    $ClusterId = $clusters[0].cluster_id
    Write-Host "Cluster Id for $ClusterName is: $ClusterId"
    return $ClusterId
}

# ----------------------------------------- #
# Install ClusterLibraries
# ----------------------------------------- #
function Install-ClusterLibraries {
    param(
        [String]$ClusterName
    )

    $ClusterId = Get-ClusterIdByName -ClusterName $ClusterName
    # Create the JSON payload
    $jsonPayload = @"
{
    "cluster_id": "$clusterId",
    "libraries": [
        {
            "requirements": "/Workspace/Users/chi.adiukwu@outlook.com/files/requirements.txt"
        }
    ]
}
"@

    # Display the JSON payload for debugging
    Write-Host "Generated JSON payload:"`n $jsonPayload
    databricks libraries install --json $jsonPayload
}

# ----------------------------------------- #
# Create a Secret Scope
# ----------------------------------------- #
function Create-AzureBackedScope {
    param(
        [string]$ScopeName,
        [string]$KeyVaultName,
        [string]$ResourceID
    )

    # Check if the scope already exists
    $ExistingScopes = databricks secrets list-scopes | ConvertFrom-Json
    if ($ExistingScopes | Where-Object { $_.name -eq $ScopeName }) {
        Write-Host "Secret scope '$ScopeName' already exists. Skipping creation." -ForegroundColor Yellow
        return
    }

    # Create the secret scope
    Write-Host "Creating secret scope: $ScopeName..."
    $KeyVaultUri = "https://$KeyVaultName.vault.azure.net/"
    $SecretScope = '{"scope":"'+$ScopeName+'","scope_backend_type":"AZURE_KEYVAULT","backend_azure_keyvault":{"resource_id":"'+$ResourceID+'","dns_name":"'+$KeyVaultUri+'"}}'
    databricks secrets create-scope --json $SecretScope
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

    $ExistingScopes = databricks secrets list-scopes -o json | ConvertFrom-Json | Where-Object { $_.name -eq $ScopeName }
    if ($ExistingScopes.name) {
        # Add secret
        Write-Host "Scope `"$ScopeName`" exists"
        Write-Host "Adding/Updating `"$KeyName`""
        $Secret = '{"scope":"' + $ScopeName + '","key":"' + $KeyValue + '","string_value":"' + $KeyValue + '"}'
        databricks secrets put-secret --json $Secret
        Write-Host "Secret `"$KeyName`" sucessfully added in scope `"$ScopeName`""
    }
    Else {
        Write-Host "Scope does not exist, creating `"$ScopeName`""
        databricks secrets create-scope $ScopeName
        Write-Host "Scope Created, Adding Secret `"$KeyName`""
        $Secret = '{"scope":"' + $ScopeName + '","key":"' + $KeyValue + '","string_value":"' + $KeyValue + '"}'
        databricks secrets put-secret --json $Secret
        Write-Host "Secret `"$KeyName`" sucessfully added in scope `"$ScopeName`""
    }
}