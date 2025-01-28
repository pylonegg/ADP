param resourceLocation string
param purviewAccountName string 
param purviewManagedRGName string


//Purview Account
resource r_purviewAccount 'Microsoft.Purview/accounts@2020-12-01-preview' = {
  name: purviewAccountName
  location: resourceLocation
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    publicNetworkAccess: 'Enabled' //Required for PostDeployment Scripts Purview API calls. Post Deployment Script to disable it if networkIsolationMode == vNet.
    managedResourceGroupName: purviewManagedRGName
  }
}

output purviewAccountID string = r_purviewAccount.id
output purviewAccountName string = r_purviewAccount.name
output purviewIdentityPrincipalID string = r_purviewAccount.identity.principalId
output purviewScanEndpoint string = r_purviewAccount.properties.endpoints.scan
output purviewAPIVersion string = r_purviewAccount.apiVersion
output purviewManagedStorageAccountID string = r_purviewAccount.properties.managedResources.storageAccount
output purviewManagedEventHubNamespaceID string = r_purviewAccount.properties.managedResources.eventHubNamespace
