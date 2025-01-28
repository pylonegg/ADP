param keyVaultName string
param networkIsolationMode string

//Key Vault
resource r_keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVaultName
  location: resourceGroup().location
  properties:{
    tenantId: subscription().tenantId
    enabledForDeployment:true
    enableSoftDelete:true
    sku:{
      name:'standard'
      family:'A'
    }
    networkAcls: {
      defaultAction: (networkIsolationMode == 'vNet')? 'Deny' : 'Allow'
      bypass:'AzureServices'
    }
    accessPolicies:[]
  }
}


output keyVaultID string = r_keyVault.id
