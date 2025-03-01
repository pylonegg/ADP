@description('Resource name prefix')
param name_prefix string

param sqlServer_name              string = '${name_prefix}-sql01'
param sqlServerDatabase_name      string = '${name_prefix}-01db'

@secure()
param adminPassword string
param adminLogin    string


// SQL Server Resource
resource SQL_Server 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServer_name
  tags: resourceGroup().tags
  location: resourceGroup().location
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    publicNetworkAccess: 'SecuredByPerimeter'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Database on SQL Server Resource
resource Database 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: sqlServerDatabase_name
  parent: SQL_Server
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}
