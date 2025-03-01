@description('Resource name prefix')
param name_prefix string

param virtualNetwork_name             string
param databricksWorkspace_name        string = '${name_prefix}-dbks01'
param managedResourceGroupName        string = 'databricks-rg-${databricksWorkspace_name}-${uniqueString(databricksWorkspace_name, resourceGroup().id)}'
param databricksAccessConnector_name  string = 'databricks-1'

@description('Specifies whether to deploy Azure Databricks workspace with Secure Cluster Connectivity (No Public IP) enabled or not')
param disablePublicIp bool = true

@description('The pricing tier of workspace.')
@allowed([
  'standard'
  'premium'
])
param pricingTier string = 'premium'

@description('Public Network Access.')
param publicNetworkAccess string = 'Enabled'

@description('Indicates whether to retain or remove the AzureDatabricks outbound NSG rule - possible values are AllRules or NoAzureDatabricksRules.')
@allowed([
  'AllRules'
  'NoAzureDatabricksRules'
])
param requiredNsgRules string = 'AllRules'

// Lookup Network
resource VirtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: virtualNetwork_name
}

// DataBricks Workspace
resource Workspace 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: databricksWorkspace_name
  location: resourceGroup().location
  tags: resourceGroup().tags

  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: managedResourceGroup.id
    parameters: {
      customVirtualNetworkId: {
        value: VirtualNetwork.id
      }
      customPublicSubnetName: {
        value: 'public-subnet'
      }
      customPrivateSubnetName: {
        value: 'private-subnet'
      }
      enableNoPublicIp: {
        value: disablePublicIp
      }
    }
    publicNetworkAccess: publicNetworkAccess
    requiredNsgRules: requiredNsgRules
  }
}

resource managedResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  scope: subscription()
  name: managedResourceGroupName
}


resource AccessConnector 'Microsoft.Databricks/accessConnectors@2023-05-01' = {
  name: databricksAccessConnector_name
  location: resourceGroup().location
  tags: resourceGroup().tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
  }
}
