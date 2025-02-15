param backupInstance_name string
param storageAccountid string
param storageAccountName string
param resourceLocation string
param backupPolicyid string
param vault_name string

var resourceType = 'Microsoft.Storage/storageAccounts'
var dataSourceType = 'Microsoft.Storage/storageAccounts/blobServices'

resource vault_resource 'Microsoft.DataProtection/BackupVaults@2023-05-01' existing = {
  name: vault_name
}

// Back Up Instance
resource backupInstance 'Microsoft.DataProtection/backupvaults/backupInstances@2023-05-01' = {
  parent: vault_resource
  name: backupInstance_name
  properties: {
    objectType: 'BackupInstance'
    dataSourceInfo: {
      objectType: 'Datasource'
      resourceID: storageAccountid
      resourceName: storageAccountName
      resourceType: resourceType
      resourceUri: storageAccountid
      resourceLocation: resourceLocation
      datasourceType: dataSourceType
    }
    policyInfo: {
      policyId: backupPolicyid
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

// Outputs
output Instance_Name string = backupInstance.name
