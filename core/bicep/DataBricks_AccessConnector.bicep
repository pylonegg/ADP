@description('Connector Name')
param name string = 'ADLS_Connector_Dbricks'

@description('Location.')
param location string

@description('Tags')
param tags object

resource Dbricks_AccessConnector 'Microsoft.Databricks/accessConnectors@2023-05-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
  }
}

// Outputs
output Dbricks_AccessConnector_name string = Dbricks_AccessConnector.name
