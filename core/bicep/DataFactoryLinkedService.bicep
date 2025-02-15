@description('Data Lake URL')
param DLurl string

@description('Key Vault URL')
param KVurl string

@description('Integrated Runtime Managed Reference')
param  integrated_runtime_name string

// Deployment Resource - Exsisting
param Datafactory_Name string
param ADLS_Name string
param SA_Name string


// Data Factory 
resource DataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: Datafactory_Name
}

// Data Lake 
resource DataLake 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: ADLS_Name
}

// Storage V2 
resource StorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: SA_Name
}

// Linked Service | Key Vault 
resource LinkedService_KV 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  parent: DataFactory
  name: 'keyvaultlinkedService'
  properties: {
    type: 'AzureKeyVault'
    typeProperties: {
      baseUrl: KVurl
    }
  }
}

// Linked Service | Data Lake Storage
resource LinkedService_DL 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: DataFactory
  name: 'datalakelinkedService'
  properties: {
    type: 'AzureBlobFS'
    typeProperties: {
      accountKey: DataLake.listKeys().keys[0].value
      url: DLurl
    }
    connectVia: {
      referenceName: integrated_runtime_name
      type: 'IntegrationRuntimeReference'
    }
  }
}

// Linked Service | Backup StorageV2 
resource LinkedService_SA 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  parent: DataFactory
  name: 'storagelinkedService'
  properties: {
    type: 'AzureBlobStorage'
    typeProperties: {
      connectionString:'DefaultEndpointsProtocol=https;AccountName=${StorageAccount.name};AccountKey=${StorageAccount.listKeys().keys[0].value}'
    }
    connectVia: {
      referenceName: integrated_runtime_name
      type: 'IntegrationRuntimeReference'
    }
  }
}

// Linked Service | SFTP 
resource LinkedService_SFTP 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: DataFactory
  name: 'SFTPlinkedService'
  properties: {
    annotations: [
    ]
    type: 'Sftp'
    typeProperties: {
      host: 'bdouk.goanywhere.cloud'
      port: 22
      skipHostKeyValidation: true
      authenticationType: 'SshPublicKey'
      userName: 'BDO_Advisory_DataAnalytics_Prod'
    }
  }
}

// Outputs
output datafactory_linkedservice_dl string = LinkedService_DL.name
output datafactory_linkedService_kv string = LinkedService_KV.name
output datafactory_linkedService_sa string = LinkedService_SA.name
output datafactory_linkedService_sftp string = LinkedService_SFTP.name
