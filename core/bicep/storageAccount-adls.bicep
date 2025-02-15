@description('Storage Account Name.')
param storageaccount_name string

@description('Key Vault Name.')
param keyvault_name string

@description('Storage Account sku')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageaccount_sku string

@description('Storage account kind')
@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param storage_kind string = 'StorageV2'

@description('Storage account access tier, Hot  or Cool')
@allowed([
  'Hot'
  'Cool'
])
param storage_tier string = 'Hot'

@description('Containers')
param container_names array = [
  'adf-pipeline-logs'
]

// Data Lake Gen 2 - Storage Account
resource StorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageaccount_name
  location: resourceGroup().location
  tags: resourceGroup().tags
  kind: storage_kind
  properties: {
    accessTier: storage_tier
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    isHnsEnabled: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    encryption: {
      requireInfrastructureEncryption: true
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
        }
      }
    }
  }
  sku: {
    name: storageaccount_sku
  }
}

// Blob Services - Settings
resource Blob_Services 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: StorageAccount
  name: 'default'
  properties: {
    lastAccessTimeTrackingPolicy: {
      blobType: [
        'string'
      ]
      enable: true
      name: 'AccessTimeTracking'
      trackingGranularityInDays: 1
    }
  }
}

// Lifecycle Management
resource Lifecycle_Manage 'Microsoft.Storage/storageAccounts/managementPolicies@2023-01-01' = {
  name: 'default'
  parent: StorageAccount
  properties: {
    policy: {
      rules: [
        {
          definition: {
            actions: {
              baseBlob: {
                tierToArchive: {
                  daysAfterLastTierChangeGreaterThan: 7
                  daysAfterModificationGreaterThan: 90
                }
                tierToCool: {
                  daysAfterLastAccessTimeGreaterThan: 30
                }
              }
            }
            filters: {
              blobTypes: [
                'blockBlob'
              ]
            }
          }
          enabled: true
          name: 'LifecycleMain'
          type: 'Lifecycle'
        }
      ]
    }
  }
    dependsOn: [
    Blob_Services
  ]
}

// Create Containers Resoruce
resource Containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = [for containerName in container_names: {
  name: containerName
  parent: Blob_Services
  properties: {
    publicAccess: 'None'
  }
}]


@description('Get reference to Key Vault')
resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyvault_name
}

@description('Add Storage account secret to KeyVault')
resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${storageaccount_name}-connectionstring'
  parent: keyVault
  properties: {
     attributes: {
       enabled: true
     }
     contentType: 'string'
    value: StorageAccount.listKeys().keys[0].value
  }
}
