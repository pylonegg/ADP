param resourceLocation            string
param sqlServerName               string
param networkIsolationMode        string
param aadAdminObjectId            string
param databaseNames               array
param tags                        object
param admin_login                 string
@secure()
param admin_password              string


@description('Deploy Sql Server Resource')
resource r_sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: resourceLocation
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: admin_login
    administratorLoginPassword: admin_password
    publicNetworkAccess: networkIsolationMode == 'vNet' ? 'Disabled' : 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'Group'
      login: 'AADServerAdmin'
      sid: aadAdminObjectId
      tenantId: tenant().tenantId
    }
  }
}

@description('Deploy Sql Server Database Resources')
resource r_sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = [for databaseName in databaseNames: {
  parent: r_sqlServer
  name: databaseName
  location: resourceLocation
  sku: {
    name: 'basic'
  }
}]
