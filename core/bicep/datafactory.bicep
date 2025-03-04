@description('Resource name prefix.')
param keyvault_name           string
param datafactory_name        string


// Data Factory Resource
resource DataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: datafactory_name
  location: resourceGroup().location
  tags: resourceGroup().tags
  identity: {
    type: 'SystemAssigned'
  }
}

resource KeyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyvault_name
}

resource KeyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  name: 'add'
  parent: KeyVault
  properties:{
    accessPolicies: [
      {
        objectId: DataFactory.identity.principalId
        tenantId: subscription().tenantId
        permissions: {
          secrets: ['get']
        }
      }
    ]
  }
}
