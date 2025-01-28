param databricksWorkspaceName string
param pricingTier string


// Databricks
resource r_databricksWorkspace 'Microsoft.Databricks/workspaces@2018-04-01' = {
  name: databricksWorkspaceName
  location: resourceGroup().location
  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: managedResourceGroup.id
    parameters: {
      enableNoPublicIp: {
        value: false
      }
    }
  }
}

var managedResourceGroupName = '${databricksWorkspaceName}-mrg'

resource managedResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  scope: subscription()
  name: managedResourceGroupName
}

output workspace object = r_databricksWorkspace.properties
