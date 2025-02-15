param storageaccount_location string
param storageaccount_tags object
param StorageAccountName string
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
param storage_sku string
param SubnetId string
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
param privateEndpointblob string

param backupVaultid string
param backupVaultPrincleId string

param adfid string
param adfPrincleId string


@description('Containers')
param container_names array = [
'archive'
]

@description('Data Lake connection string in Key Vault')
var backupstorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${StorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${StorageAccount.listKeys().keys[0].value}'

@description('Storage Account Backup Contributor')
var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1')

@description('Storage Blob Data Contributor')
var roleDefinitionId1 = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

// Storage Account v2
resource StorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: StorageAccountName
  location: storageaccount_location
  tags: storageaccount_tags
  kind: storage_kind
  properties: {
    accessTier: storage_tier
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    allowCrossTenantReplication: true
    networkAcls: {
      defaultAction: 'Deny'
    }
    encryption: {
       requireInfrastructureEncryption: true
    }
  }
  sku: {
    name: storage_sku
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

// Private Endpoint Resource - blob
resource Private_Endpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: privateEndpointblob
  location: storageaccount_location
  properties: {
    subnet: {
      id: SubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'StoragePE_blob'
        properties: {
          privateLinkServiceConnectionState: {
            status: 'Approved'
          }
          privateLinkServiceId: StorageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

// Role Assignment Mnaged Identity for vault to Storagev2 Account - For backup Instance
resource RBAC_BackUpVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(backupVaultid, roleDefinitionId, StorageAccount.id)
  scope: StorageAccount
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: backupVaultPrincleId
    principalType: 'ServicePrincipal'
  }
}

// Role Assignment Managed Identity for ADF to Storage Account
resource RBAC_ADF 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(adfid, roleDefinitionId1, StorageAccount.id)
  scope: StorageAccount
  properties: {
    roleDefinitionId: roleDefinitionId1
    principalId: adfPrincleId
    principalType: 'ServicePrincipal'
  }
}

output backup_storageaccount_resource string = StorageAccount.id
output backup_storageaccount_name string = StorageAccount.name
output backupstorage_connectionstring string = backupstorageConnectionString
