@description('Resource name prefix')
param name_prefix string

param keyvault_name               string = '${name_prefix}-kv01'
param backupVault_name            string = '${name_prefix}-vault01'


@description('Storage Account Name.')
param storageaccount_name string

@description('Toggle Backup storage account')
param deploy_BackupInstance bool = false

@description('Hierachichal name space/isDataLake.')
param isHnsEnabled bool = false

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
param storageaccount_sku string = 'Standard_LRS'

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
param container_names array

param deploy_lifeCycleManagement bool



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
    isHnsEnabled: isHnsEnabled
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
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
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

// Create Containers Resoruce
resource Containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = [for containerName in container_names: {
  name: containerName
  parent: Blob_Services
  properties: {
    publicAccess: 'None'
  }
}]


resource Lifecycle_Manage 'Microsoft.Storage/storageAccounts/managementPolicies@2023-01-01' = if(deploy_lifeCycleManagement){
  name: 'default'
  parent: StorageAccount
  dependsOn: Containers
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
}



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



// Create BackUp Instance
resource BackupVault 'Microsoft.DataProtection/BackupVaults@2023-05-01' existing = {
  name: backupVault_name
}
resource BackupPolicy 'Microsoft.DataProtection/backupVaults/backupPolicies@2021-01-01' existing = {
  parent:BackupVault
  name: 'GoldPolicy'
}

resource existingBackupInstance 'Microsoft.DataProtection/backupvaults/backupInstances@2023-05-01' existing = {
  parent: BackupVault
  name: storageaccount_name
}

resource backupInstance 'Microsoft.DataProtection/backupvaults/backupInstances@2023-05-01' = if(deploy_BackupInstance && empty(existingBackupInstance.id)){
  parent: BackupVault
  name: storageaccount_name
  properties: {
    friendlyName:storageaccount_name
    objectType: 'BackupInstance'
    dataSourceInfo: {
      objectType: 'Datasource'
      resourceID: StorageAccount.id
      resourceName: StorageAccount.name
      resourceType: 'Microsoft.Storage/storageAccounts'
      resourceUri: StorageAccount.id
      resourceLocation: resourceGroup().location
      datasourceType: 'Microsoft.Storage/storageAccounts/blobServices'
    }
    policyInfo: {
      policyId: BackupPolicy.id
      policyParameters: {
        backupDatasourceParametersList: [
          {
            objectType: 'BlobBackupDatasourceParameters'
            containersList: [
              'archive'
            ]
          }
        ]
      }
    }
  }
}
