param storageaccount_name string
param storageaccountBackup_name string
param datafactory_name string



// Get Role definition Id's
// -------------------------------------------------------------------------
@description('Storage Account Backup Contributor')
var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1')

@description('Storage Blob Data Contributor')
var roleDefinitionId1 = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')


// Get References to existing resources
// -------------------------------------------------------------------------


resource ADLSStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageaccount_name
}

resource BackupStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageaccountBackup_name
}

resource DataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: datafactory_name
}

// Assign Rbac
// -------------------------------------------------------------------------
// // Role Assignment Managed Identity for vault to DataLake - For backup Instance
// resource RBAC_BackUpVault_ADLS 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(backupVaultid, roleDefinitionId, ADLSStorageAccount.id)
//   scope: ADLSStorageAccount
//   properties: {
//     roleDefinitionId: roleDefinitionId
//     principalId: backupVaultPrincleId
//     principalType: 'ServicePrincipal'
//   }
// }

// Role Assignment Managed Identity for ADF to DataLake
resource RBAC_ADF_ADLS 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(DataFactory.id, roleDefinitionId1, ADLSStorageAccount.id)
  scope: ADLSStorageAccount
  properties: {
    roleDefinitionId: roleDefinitionId1
    principalId: DataFactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// // Role Assignment Mnaged Identity for vault to Storagev2 Account - For backup Instance
// resource RBAC_BackUpVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(backupVaultid, roleDefinitionId, BackupStorageAccount.id)
//   scope: BackupStorageAccount
//   properties: {
//     roleDefinitionId: roleDefinitionId
//     principalId: backupVaultPrincleId
//     principalType: 'ServicePrincipal'
//   }
// }

// Role Assignment Managed Identity for ADF to Storage Account
resource RBAC_ADF 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(DataFactory.id, roleDefinitionId1, BackupStorageAccount.id)
  scope: BackupStorageAccount
  properties: {
    roleDefinitionId: roleDefinitionId1
    principalId: DataFactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
