@description('key vault name.')
param keyvault_name string

param subnet_id string

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: 'my_vnet'
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: 'my_subnet'
  parent: vnet
}

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
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: [
        {
          value: '13.66.200.132/32'
        }
        {
          value: '23.100.71.251/32'
        }
        {
          value: '40.78.82.214/32'
        }
        {
          value: '51.105.4.145/32'
        }
        {
          value: '52.166.166.111/32'
        }
      ]
      virtualNetworkRules: [
        {
          id: subnet.id
          ignoreMissingVnetServiceEndpoint: true
        }
      ]
    }
  }
}


//Outputs
output keyvault_uri string = KeyVault.properties.vaultUri
output keyvault_name string = KeyVault.name

