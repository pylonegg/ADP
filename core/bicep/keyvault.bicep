@description('Resource name prefix')
param name_prefix string

@description('key vault name.')
param keyvault_name           string = '${name_prefix}-kv01'

// Key Vault Resource
resource KeyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyvault_name
  location: resourceGroup().location
  tags: resourceGroup().tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    enablePurgeProtection: true
    enableRbacAuthorization: true
    softDeleteRetentionInDays: 90
    accessPolicies: []
  }
}
