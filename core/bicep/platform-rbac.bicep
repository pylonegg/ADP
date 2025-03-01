@description('Resource name prefix')
param name_prefix string

param storageaccount_name             string = '${replace(name_prefix, '-','')}adls01'
param storageaccountBackup_name       string = '${replace(name_prefix, '-','')}bkstg01'
param datafactory_name                string = '${name_prefix}-adf01'
param backupVault_name                string = '${name_prefix}-vault01'
param sqlServer_name                  string = '${name_prefix}-sql01'
param databricksAccessConnector_name  string = 'databricks-1'


// Roles --------------------------------------------------------------
@description('Storage Account Backup Contributor')
var StorageAccountBackupContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1')

@description('Storage Blob Data Contributor')
var StorageBlobDataContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')


// Resource Resources  -----------------------------------------------------
resource ADLSStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageaccount_name
}

resource BackupStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageaccountBackup_name
}

resource DataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: datafactory_name
}

resource BackupVault 'Microsoft.DataProtection/BackupVaults@2023-05-01' existing = {
  name: backupVault_name
}

resource SQLServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServer_name
}

resource AccessConnector 'Microsoft.Databricks/accessConnectors@2023-05-01' existing = {
  name: databricksAccessConnector_name
}



// ACCESS TO DATALAKE -------------------------------------------------------------
// --------------------------------------------------------------------------------
// DATAFACTORY
resource RBAC_ADF_ADLS 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(DataFactory.id, StorageBlobDataContributor, ADLSStorageAccount.id)
  scope: ADLSStorageAccount
  properties: {
    roleDefinitionId: StorageBlobDataContributor
    principalId: DataFactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// DATABRICKS
resource RBAC_XAC_ADLS 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(AccessConnector.id, StorageBlobDataContributor, ADLSStorageAccount.id)
  scope: ADLSStorageAccount
  properties: {
    roleDefinitionId: StorageBlobDataContributor
    principalId: AccessConnector.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// BACKUP VAULT
resource RBAC_BackUpVault_ADLS 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(BackupVault.id, StorageAccountBackupContributor, ADLSStorageAccount.id)
  scope: ADLSStorageAccount
  properties: {
    roleDefinitionId: StorageAccountBackupContributor
    principalId: BackupVault.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// SQL SERVER
resource RBAC_SQL_ADLS 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(SQLServer.id, StorageBlobDataContributor, ADLSStorageAccount.id)
  scope: ADLSStorageAccount
  properties: {
    roleDefinitionId: StorageBlobDataContributor
    principalId: SQLServer.identity.principalId
    principalType: 'ServicePrincipal'
  }
}



// ACCESS TO BACKUP STORAGE ACCOUNT -------------------------------------------------
// ----------------------------------------------------------------------------------
// BACKUP VAULT
resource RBAC_BackUpVault_Backup 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(BackupVault.id, StorageAccountBackupContributor, BackupStorageAccount.id)
  scope: BackupStorageAccount
  properties: {
    roleDefinitionId: StorageAccountBackupContributor
    principalId: BackupVault.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// DATAFACTORY
resource RBAC_ADF_Backup 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(DataFactory.id, StorageBlobDataContributor, BackupStorageAccount.id)
  scope: BackupStorageAccount
  properties: {
    roleDefinitionId: StorageBlobDataContributor
    principalId: DataFactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
