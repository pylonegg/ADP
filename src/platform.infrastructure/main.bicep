@description('Environment to deploy the resources in to.')
@allowed([
  'Development'
  'Integration'
  'Test'
  'UAT'
  'Production'
])
param environment string

@description('Location for all the resources.')
param location string = resourceGroup().location

@description('Admin Login Username')
param adminLogin string

@description('Admin Password')
@secure()
param adminPassword string

@description('Subnet ID')
param SubnetId string

// Key Params
param ADLS_Name string
param storage_sku string
param ADLS_PE_Blob string
param ADLS_PE_dfs string
param SA_Name string
param SA_PE_Blob string
param Vault_Name string
param vaultStorageRedundancy string
param Keyvault_Name string
param Datafactory_Name string
param integrated_runtime_name string
param backup_pipeline string
param sqlServerName string
param Server_PE_sql string
param workspaceName string
param privateEndpointSubnetCidr string
param privateSubnetCidr string
param publicSubnetCidr string
param vnetCidr string
param vnetNameDbks string
param Dbks_NSG_Name string

// Variables
var DLurl = 'https://${DataLake.outputs.storageaccount_name}.dfs.${az.environment().suffixes.storage}'

var KVurl = 'https://${KeyVault.outputs.keyvault_name}${az.environment().suffixes.keyvaultDns}'

@description('Name prefix for all the resources.')
var resourcePrefix = replace(resourceGroup().name, 'rg', '')

@description('Tags for all the resources.')
var tags = resourceGroup().tags



// Modules
// Data Factory
module DataFactory '../../core/bicep/DataFactory.bicep' = {
  name: 'Data_Factory_Deploy'
  params: {
    environment: environment
    datafactory_name: Datafactory_Name
    datafactory_location: location
    integrated_runtime_name: integrated_runtime_name
    repositoryName: 'Advisory_DataAnalytics_Platform'
    repositoryType: 'FactoryVSTSConfiguration'
    repositoryAccountName: 'bdouk'
    repositoryProjectName: 'Applications Support'
    repositoryCollaborationBranch: 'main'
    repositoryRootFolder: 'main.bicep'
  }
}

// Key Vault + Linked to DF
module KeyVault '../../core/bicep/KeyVault.bicep' = {
  name: 'Key_Vault_Deploy'
  params: {
    keyvault_name: Keyvault_Name
    keyvault_tags: tags
    keyvault_location: location
    keyvault_tenantid: subscription().tenantId
    datafactory_principalid: DataFactory.outputs.datafactoryPrincipleID
    storageaccount_name: DataLake.outputs.storageaccount_name
    storageaccount_connectionstring: DataLake.outputs.storageaccount_connectionstring
    backupstorage_connectionstring: StorageV2_Backup.outputs.backupstorage_connectionstring
    storagebackup_name: StorageV2_Backup.outputs.backup_storageaccount_name
    SubnetId: SubnetId
  }
}

// SQL Server + DB + Private Endpoint
module sql_Server '../../core/bicep/sqlServer.bicep' = {
  name: 'SQL_Server_Deploy'
  params: {
    sqlServerName: sqlServerName
    adminLogin: adminLogin
    adminPassword: adminPassword
    databaseName: '${resourcePrefix}db'
    serverLocation: location
    privateEndpointName: Server_PE_sql
    SubnetId: SubnetId
  }
}

// Data Lake Gen 2 - Storage Account + Private Endpoint
module DataLake '../../core/bicep/DataLakeStorage.bicep' = {
  name: 'DataLake_Storage_Deploy'
  params: {
    storageaccount_name: ADLS_Name
    storageaccount_tags: tags
    storageaccount_location: location
    privateEndpointblob: ADLS_PE_Blob
    privateEndpointdfs: ADLS_PE_dfs
    SubnetId: SubnetId
    backupVaultid: Backup_Vault.outputs.backupVaultID
    backupVaultPrincleId: Backup_Vault.outputs.backupVaultPrincipleID
    storage_sku: storage_sku
    adfid: DataFactory.outputs.datafactoryID
    adfPrincleId: DataFactory.outputs.datafactoryPrincipleID
  }
}

// Storagev2 - BackUp Location 
module StorageV2_Backup '../../core/bicep/StorageAccount.bicep' = {
  name: 'StorageV2_backup_Deploy'
  params: {
    privateEndpointblob: SA_PE_Blob
    storageaccount_tags: tags
    storageaccount_location: location
    StorageAccountName: SA_Name
    SubnetId: SubnetId
    backupVaultid: Backup_Vault.outputs.backupVaultID
    backupVaultPrincleId: Backup_Vault.outputs.backupVaultPrincipleID
    storage_sku: storage_sku
    adfid: DataFactory.outputs.datafactoryID
    adfPrincleId: DataFactory.outputs.datafactoryPrincipleID
  }
}

// DataBricks + Workspace
module DataBricks '../../core/bicep/DataBricks.bicep' = {
  name: 'DataBricks_Deploy'
  params: {
    disablePublicIp: false
    workspaceName: workspaceName
    location: location
    privateEndpointSubnetCidr: privateEndpointSubnetCidr
    privateSubnetCidr: privateSubnetCidr
    publicSubnetCidr: publicSubnetCidr
    vnetCidr: vnetCidr
    vnetNameDbks: vnetNameDbks
    Dbks_NSG_Name: Dbks_NSG_Name
  }
}

// DataBricks Access Connector
module DataBricks_AccessConnector '../../core/bicep/DataBricks_AccessConnector.bicep' = {
  name: 'DataBricks_AccessConnector_Deploy'
  params: {
    location: location
    tags: tags
  }
}

// BackUp Vault + Policy
module Backup_Vault '../../core/bicep/BackupVault.bicep' = {
  name: 'BackUpVault_Deploy'
  params: {
    vault_name: Vault_Name
    location: location
    vaultStorageRedundancy: vaultStorageRedundancy
  }
}

// BackUp Vault Instance
module BackUp_Vault_Instance '../../core/bicep/BackupVault_Instance.bicep' = {
  name: 'Backup_Instance_Deploy'
  params: {
    backupPolicyid: Backup_Vault.outputs.backupPolicy_ID
    resourceLocation: location
    storageAccountid: StorageV2_Backup.outputs.backup_storageaccount_resource
    storageAccountName: StorageV2_Backup.outputs.backup_storageaccount_name
    backupInstance_name: '${resourcePrefix}instance'
    Vault_Name: Vault_Name
  }
  dependsOn: [
    StorageV2_Backup
    Backup_Vault
    DataLake
  ]
}


// Custom Advisory RBAC Role 
module Custom_Storage_Role '../../core/bicep/CustomRoles.bicep' = {
  name: 'Custom_RBAC_Storage_Roles'
  params: {
    StorageAccountName: DataLake.outputs.storageaccount_name
  }
  dependsOn:[
    DataLake
  ]
}

// Locks
module ResoruceGroup_lock '../../core/bicep/ApplyLock.bicep' = {
  name: 'Resource_Lock_Deploy'
  scope: resourceGroup()
  params: {}
}

/* Diagonstics
module Diagonstics '../../core/bicep/Monitoring.bicep' = {
  name: 'Diagonstics_Deploy'
  params: {
    ADLS_Name: ADLS_Name
    Datafactory_Name: Datafactory_Name
    SA_Name: SA_Name
    Vault_Name: Vault_Name
  }
}*/



// Pipeline Outputs
output Resource_Group string = resourceGroup().name
output DataBricks_Workspace_Resource_Created string = DataBricks.outputs.workspace_name
output DataBricks_Workspace_vNet string = DataBricks.outputs.DBKS_vnet_name
output DataFactory_Resource_Created string = DataFactory.outputs.df_name
output DataLake_Resource_Created string = DataLake.outputs.storageaccount_name
output DataLake_Lifecycle_ManagementPolicy string = DataLake.outputs.LifecycleManagement_name
output DataLake_Containers array = DataLake.outputs.Container_names
output DataLake_PrivateEndpoint_blob string = DataLake.outputs.storageaccount_privateendpoint_blob
output DataLake_PrivateEndpoint_dfs string = DataLake.outputs.storageaccount_privateendpoint_dfs
output KeyVault_Resource_Created string = KeyVault.outputs.keyvault_name
output Storagev2_Backup string = StorageV2_Backup.outputs.backup_storageaccount_name
output sqlServer_Resoruce_Created string = sql_Server.outputs.sqlServer_name
output sqlDatabase_Resource_Created string = sql_Server.outputs.database_name
output sqlPrivateEndpoint_Resource_Created string = sql_Server.outputs.privateEndpoint_name
output DataFactory_Integrated_Runtime string = DataFactory.outputs.integrated_runtime_name 
output Backup_Vault_Creted string = Backup_Vault.outputs.backupVaultName
output Backup_Policy_Created string = Backup_Vault.outputs.backupPolicyName
output ResourceGroup_Lock string = ResoruceGroup_lock.outputs.ResourceGroup_Lock
output ADLS_Custom_Role_1 string = Custom_Storage_Role.outputs.custom_role_1
output ADLS_Custom_Role_2 string = Custom_Storage_Role.outputs.custom_role_2
output DataBricks_to_ADLS_Connector_Created string = DataBricks_AccessConnector.outputs.Dbricks_AccessConnector_name
