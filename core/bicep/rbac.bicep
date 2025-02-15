// Variables

@description('Data Lake connection string in Key Vault')
var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${ADLS.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${DataLake.listKeys().keys[0].value}'

@description('Storage Account Backup Contributor')
var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1')

@description('Storage Blob Data Contributor')
var roleDefinitionId1 = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')



// Role Assignment Managed Identity for vault to DataLake - For backup Instance
resource RBAC_BackUpVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(backupVaultid, roleDefinitionId, ADLS.id)
  scope: ADLS
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: backupVaultPrincleId
    principalType: 'ServicePrincipal'
  }
}

// Role Assignment Managed Identity for ADF to DataLake
resource RBAC_ADF 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(adfid, roleDefinitionId1, ADLS.id)
  scope: ADLS
  properties: {
    roleDefinitionId: roleDefinitionId1
    principalId: adfPrincleId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output storageaccount_resource string = ADLS.id
output storageaccount_name string = storageaccount_name
output storageaccount_connectionstring string = storageAccountConnectionString
output LifecycleManagement_name string = Lifecycle_Manage.name
output Container_names array = container_names
output storageaccount_dfs_endpoint string = ADLS.properties.primaryEndpoints.dfs
output storageaccount_privateendpoint_blob string = Blob_PrivateEnd.name
output storageaccount_privateendpoint_dfs string = DFS_PrivateEnd.name
