@description('Resource name prefix')
param name_prefix string

param keyvault_name               string = '${name_prefix}-kv01'
param sqlServer_name              string = '${name_prefix}-sql01'
param privateEndpointADLSdfs      string = '${name_prefix}-dfs-pe01'
param privateEndpointSql          string = '${name_prefix}-sql-pe01'
param privateEndpointADLSBlob     string = '${name_prefix}-blob-pe01'
param privateEndpointBackupBlob   string = '${name_prefix}bk-blob-pe01'
param storageaccountADLS_name     string = '${replace(name_prefix, '-','')}adls01'
param storageaccountBackup_name   string = '${replace(name_prefix, '-','')}bkstg01'

param virtualNetwork_name         string

@description('Name of central BDO vnet of west eu')
param centralVirtualNetwork_name string

@description('Name of central subnet BDO vnet of west eu')
param centralVirtualNetwork_resourceGroup string

@description('Name of central subnet BDO vnet of west eu')
param centralSubnet_name string = 'AdvisoryDataAnalytics'

//-------------------------------------------------------------------------------------------
// Lookup resources
// -------------------------------------------------------------------------------------------
resource VirtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01'existing ={
  name: virtualNetwork_name
}
// Get Private Endpoint Subnet
resource PrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: 'default'
  parent: VirtualNetwork
}
// Get Private Endpoint Subnet
resource PrivateSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: 'private-subnet'
  parent: VirtualNetwork
}
// Get Private Endpoint Subnet
resource PublicSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: 'public-subnet'
  parent: VirtualNetwork
}

// Get networking 
resource centralVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: centralVirtualNetwork_name
  scope: resourceGroup(centralVirtualNetwork_resourceGroup)
}

resource centralSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: centralSubnet_name
  parent: centralVirtualNetwork
}

// VNET Rules
var virtualNetworkRules = [
  {
    id: centralSubnet.id
  }
  {
    id: PublicSubnet.id
  }
  {
    id: PrivateSubnet.id
  }
  {
    id: PrivateEndpointSubnet.id
  }
]

//-------------------------------------------------------------------------------------------------
// Keyvault Network Configuration
//-------------------------------------------------------------------------------------------------
resource KeyVaultRules 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyvault_name
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: 90
    accessPolicies:[]
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        {
          value: '13.66.200.132/32'
        }
        {
          value: '23.100.71.251/32'
        }
        {
          value: '40.78.82.214/32'
        }
        {
          value: '51.105.4.145/32'
        }
        {
          value: '52.166.166.111/32'
        }
      ]
      virtualNetworkRules: virtualNetworkRules
    }
  } 
}


//-------------------------------------------------------------------------------------------------
// ADLS Storage Account Network Configuration
//-------------------------------------------------------------------------------------------------
resource ADLSStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing= {
  name: storageaccountADLS_name
}
resource ADLSStorageAccountRules 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageaccountADLS_name
  location: resourceGroup().location
  properties: {
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: virtualNetworkRules
    }
  } 
}

resource ADLSBlobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointADLSBlob
  location: resourceGroup().location
  dependsOn: [ADLSStorageAccountRules]
  properties: {
    subnet: {
      id: centralSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'DataLakePE_blob'
        properties: {
          privateLinkServiceConnectionState: {
            status: 'Approved'
          }
          privateLinkServiceId: ADLSStorageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

// Private Endpoint Resource - dfs
resource ADLSDFSPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointADLSdfs
  location: resourceGroup().location
  dependsOn: [ADLSBlobPrivateEndpoint]
  properties: {
    subnet: {
      id: centralSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'DataLakePE_dfs'
        properties: {
          privateLinkServiceConnectionState: {
            status: 'Approved'
          }
          privateLinkServiceId: ADLSStorageAccount.id
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
  }
}


//-------------------------------------------------------------------------------------------------
// Backup Storage Account Private Endpoint
//-------------------------------------------------------------------------------------------------
resource BackupStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing= {
  name: storageaccountBackup_name
}
resource BackuptorageAccountRules 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageaccountBackup_name
  location: resourceGroup().location
  properties: {
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: virtualNetworkRules
    }
  } 
}

resource BackupBlobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: privateEndpointBackupBlob
  location: resourceGroup().location
  properties: {
    subnet: {
      id: centralSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'StoragePE_blob'
        properties: {
          privateLinkServiceConnectionState: {
            status: 'Approved'
          }
          privateLinkServiceId: BackupStorageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}


//-------------------------------------------------------------------------------------------------
// Private Endpoint SQL Server
//-------------------------------------------------------------------------------------------------
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServer_name
}

resource SqlPublicSubnet 'Microsoft.Sql/servers/virtualNetworkRules@2024-05-01-preview' = {
  parent: sqlServer
  name: 'public-subnet'
  properties: {
    ignoreMissingVnetServiceEndpoint: true
    virtualNetworkSubnetId: PublicSubnet.id
  }
}

resource SqlPrivateSubnet 'Microsoft.Sql/servers/virtualNetworkRules@2024-05-01-preview' = {
  parent: sqlServer
  name: 'private-subnet'
  properties: {
    ignoreMissingVnetServiceEndpoint: true
    virtualNetworkSubnetId: PrivateSubnet.id
  }
}

resource SqlPrivateEndpointSubnet 'Microsoft.Sql/servers/virtualNetworkRules@2024-05-01-preview' = {
  parent: sqlServer
  name: 'privateEndpoint-subnet'
  properties: {
    ignoreMissingVnetServiceEndpoint: true
    virtualNetworkSubnetId: PrivateEndpointSubnet.id
  }
}

resource SQLPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: privateEndpointSql
  location: resourceGroup().location
  properties: {
    subnet: {
      id: centralSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'sqlServerConnection'
        properties: {
          privateLinkServiceConnectionState: {
            status: 'Approved'
          }
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}
