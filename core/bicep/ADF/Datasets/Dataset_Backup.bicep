param referenceNameDLS string 

param referenceNameSV2 string

param blobContainerName string = 'archive'

param Datafactory_Name string

// Data Factory 
resource DataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: Datafactory_Name
}

// Data Lake dataset | Root Container
resource DataLake 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: 'DataLake'
  parent: DataFactory
  properties: {
    description: 'Data Lake Root Container'
    linkedServiceName: {
      referenceName: referenceNameDLS
      type: 'LinkedServiceReference'
    }
  /*  parameters: {
      Container: {
        type: 'String'
      }
    } */
    annotations: []
    type: 'Binary'
    typeProperties: {
      location: {
        type: 'AzureBlobFSLocation'
  /*      fileSystem: {
          value: '@{dataset().Container}'
          type: 'Expression'
        } */
      }
    }
  }
}

// Storage Account dataset | Root Container
resource StorageAccount 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: 'StorageAccount'
  parent: DataFactory
  properties: {
    description: 'Backup StorageV2 Root Container'
    linkedServiceName: {
      referenceName: referenceNameSV2
      type: 'LinkedServiceReference'
    }
    parameters: {
      containers: {
        type: 'String'
      }
    }
    annotations: []
    type: 'Binary'
    typeProperties: {
     location: {
      type: 'AzureBlobStorageLocation'
      container: blobContainerName
     }
    }
  }
}

// Outputs 
output DataFactory_DataLake_Dataset string = DataLake.name
output StorageAccount_StorageAccount_Dataset string = StorageAccount.name
