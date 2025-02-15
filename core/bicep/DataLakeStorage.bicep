@description('Storage Account Name.')
param storageaccount_name string

@description('Storage Account Tags.')
param storageaccount_tags object

@description('Location.')
param storageaccount_location string

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

@description('Data Lake Storage Account Private Endpoints')
param privateEndpointblob string
param privateEndpointdfs string

@description('Subnet ID')
param SubnetId string

@description('Backup Vault IDs')
param backupVaultid string
param backupVaultPrincleId string

@description('ADF IDs')
param adfid string
param adfPrincleId string

// Variables

@description('Data Lake connection string in Key Vault')
var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${DataLake.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${DataLake.listKeys().keys[0].value}'

@description('Storage Account Backup Contributor')
var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1')

@description('Storage Blob Data Contributor')
var roleDefinitionId1 = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

// Data Lake Gen 2 - Storage Account
resource DataLake 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageaccount_name
  location: storageaccount_location
  tags: storageaccount_tags
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
    name: storage_sku
  }
}

// Blob Services - Settings
resource Blob_Services 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: DataLake
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
  parent: DataLake
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

// Private Endpoint Resource - blob
resource Blob_PrivateEnd 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointblob
  location: storageaccount_location
  properties: {
    subnet: {
      id: SubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'DataLakePE_blob'
        properties: {
          privateLinkServiceConnectionState: {
            status: 'Approved'
          }
          privateLinkServiceId: DataLake.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

// Private Endpoint Resource - dfs
resource DFS_PrivateEnd 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointdfs
  location: storageaccount_location
  properties: {
    subnet: {
      id: SubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'DataLakePE_dfs'
        properties: {
          privateLinkServiceConnectionState: {
            status: 'Approved'
          }
          privateLinkServiceId: DataLake.id
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
  }
}

// Role Assignment Managed Identity for vault to DataLake - For backup Instance
resource RBAC_BackUpVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(backupVaultid, roleDefinitionId, DataLake.id)
  scope: DataLake
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: backupVaultPrincleId
    principalType: 'ServicePrincipal'
  }
}

// Role Assignment Managed Identity for ADF to DataLake
resource RBAC_ADF 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(adfid, roleDefinitionId1, DataLake.id)
  scope: DataLake
  properties: {
    roleDefinitionId: roleDefinitionId1
    principalId: adfPrincleId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output storageaccount_resource string = DataLake.id
output storageaccount_name string = storageaccount_name
output storageaccount_connectionstring string = storageAccountConnectionString
output LifecycleManagement_name string = Lifecycle_Manage.name
output Container_names array = container_names
output storageaccount_dfs_endpoint string = DataLake.properties.primaryEndpoints.dfs
output storageaccount_privateendpoint_blob string = Blob_PrivateEnd.name
output storageaccount_privateendpoint_dfs string = DFS_PrivateEnd.name
