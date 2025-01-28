param dataFactoryName string


@description('Deploy Azure Data Factory resource')
resource r_DataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties:{
  }
}
