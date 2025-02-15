param sqlServerName string
param adminLogin string
@secure()
param adminPassword string
param databaseName string
param serverLocation string
param privateEndpointName string
param SubnetId string

// SQL Server Resource
resource SQL_Server 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: serverLocation
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
  }
}

// Database on SQL Server Resource
resource Database 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: databaseName
  parent: SQL_Server
  location: serverLocation
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

// Private Endpoint Resource
resource Private_Endpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: privateEndpointName
  location: serverLocation
  properties: {
    subnet: {
      id: SubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'sqlServerConnection'
        properties: {
          privateLinkServiceConnectionState: {
            status: 'Approved'
          }
          privateLinkServiceId: SQL_Server.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

// Outputs
output sqlServer_name string = SQL_Server.name
output database_name string = Database.name
output privateEndpoint_name string = Private_Endpoint.name
