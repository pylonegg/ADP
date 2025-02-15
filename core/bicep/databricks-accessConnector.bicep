@description('Connector Name')
param name string = 'ADLS_Connector_Dbricks'

resource Dbricks_AccessConnector 'Microsoft.Databricks/accessConnectors@2023-05-01' = {
  name: name
  location: resourceGroup().location
  tags: resourceGroup().tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
  }
}

// Outputs
output Dbricks_AccessConnector_name string = Dbricks_AccessConnector.name
