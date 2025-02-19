@description('Databricks workspace name.')
param databricksWorkspaceName string

@description('The pricing tier of workspace.')
@allowed([
  'standard'
  'premium'
])
param pricingTier string = 'premium'

// Variables
var managedResourceGroupName = '${databricksWorkspaceName}-mrg'

resource mrg 'Microsoft.Resources/resourceGroups@2024-11-01' existing = {
  scope: subscription()
  name: managedResourceGroupName
}

// DataBricks Workspace
resource Workspace 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: databricksWorkspaceName
  location: resourceGroup().location
  tags: resourceGroup().tags

  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: mrg.id
  }
}


