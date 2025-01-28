param networkIsolationMode string
param storageAccountName string
param containerNames array
param keyVaultName  string
param ctrlDeployStreaming bool

@allowed([
  'eventhub'
  'iothub'
])
param ctrlStreamIngestionService string = 'eventhub'

//var dataLakeresourceAccessRules = union(synapseAccessRule, dataShareAccessRule, streamAnalyticsJobAccessRule, purviewAccessRule, azureMLAccessRule, anomalyDetectorAccessRule, languageServiceAccessRule, iotHubAccessRule)

//Raw Data Lake Storage Account
resource r_dataLakeStorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: resourceGroup().location
  properties:{
    isHnsEnabled: true
    accessTier:'Cool'
    networkAcls: {
      defaultAction: (networkIsolationMode == 'vNet')? 'Deny' : 'Allow'
      //bypass: only required for EventHubs. All other services will have specific access rules defined in the resourceAccessRules element below.
      //Only EventHubs in the same subscription will have access to the storage account: https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security?tabs=azure-portal#trusted-access-for-resources-registered-in-your-subscription
      bypass: (ctrlDeployStreaming && ctrlStreamIngestionService == 'eventhub') ? 'AzureServices' : 'None' 
      //resourceAccessRules: dataLakeresourceAccessRules
    }
  }
  kind:'StorageV2'
  sku: {
      name: 'Standard_GRS'
  }
}

resource blob2 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  name: 'default'
  parent: r_dataLakeStorageAccount
  
}
@description('Data Lake zone containers')
resource r_dataLakeZoneContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = [for containerName in containerNames: {
  name:containerName
  parent:blob2
}]

@description('Get reference to KV')
resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

@description('Add Storage account secret to KeyVault')
resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${storageAccountName}-connectionstring'
  parent: keyVault
  properties: {
    value: r_dataLakeStorageAccount.listKeys().keys[0].value
  }
}


output dataLakeStorageAccountID     string = r_dataLakeStorageAccount.id
output dataLakeStorageAccountName   string = r_dataLakeStorageAccount.name
