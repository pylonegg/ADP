
param storageaccountADLS_name string
param storageaccountBackup_name string

@description('Data Lake Storage Account Private Endpoints')
param privateEndpointblob string
param privateEndpointdfs string

@description('Subnet ID')
param subnet_id string



// ADLS Storage Account Private Endpoint
resource ADLSStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name:storageaccountADLS_name
}

resource Blob_PrivateEnd 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointblob
  location: resourceGroup().location
  properties: {
    subnet: {
      id: subnet_id
    }
    privateLinkServiceConnections: [
      {
        name: 'DataLakePE_blob'
        properties: {
          privateLinkServiceConnectionState: {
            status: 'Approved'
          }
          privateLinkServiceId: ADLSStorageAccount.id
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
  location: resourceGroup().location
  properties: {
    subnet: {
      id: subnet_id
    }
    privateLinkServiceConnections: [
      {
        name: 'DataLakePE_dfs'
        properties: {
          privateLinkServiceConnectionState: {
            status: 'Approved'
          }
          privateLinkServiceId: ADLSStorageAccount.id
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
  }
}



// Backup Storage Account Private Endpoint
resource BackupStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageaccountBackup_name
}

resource Private_Endpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: privateEndpointblob
  location: resourceGroup().location
  properties: {
    subnet: {
      id: subnet_id
    }
    privateLinkServiceConnections: [
      {
        name: 'StoragePE_blob'
        properties: {
          privateLinkServiceConnectionState: {
            status: 'Approved'
          }
          privateLinkServiceId: BackupStorageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}
