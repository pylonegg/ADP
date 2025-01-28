param networkIsolationMode string
param ctrlDeployPrivateDNSZones bool
param ctrlDeployVirtualNetwork string
param virtualNetworkName string
param resourceLocation string = resourceGroup().location

param ctrlDeploySynapseSQLPool bool
param ctrlDeploySynapseSparkPool bool
param ctrlDeploySynapseADXPool bool
param ctrlDeployPurview bool

param dataLakeAccountName string
param synapseDefaultContainerName string
param UAMIPrincipalID string
param synapseWorkspaceName string
param synapseSqlAdminUserName string
@secure()
param synapseSqlAdminPassword string
param synapseManagedRGName string
param synapseDedicatedSQLPoolName string
param synapseSQLPoolSKU string
param synapseSparkPoolName string
param synapseSparkPoolNodeSize string
param synapseSparkPoolMinNodeCount int
param synapseSparkPoolMaxNodeCount int
param synapseADXPoolName string
param synapseADXDatabaseName string
param synapseADXPoolEnableAutoScale bool
param synapseADXPoolMinSize int
param synapseADXPoolMaxSize int

param purviewAccountID string

var storageEnvironmentDNS = environment().suffixes.storage
var dataLakeStorageAccountUrl = 'https://${dataLakeAccountName}.dfs.${storageEnvironmentDNS}'

//Synapse Workspace
resource r_synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name:synapseWorkspaceName
  location: resourceLocation
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    defaultDataLakeStorage:{
      accountUrl: dataLakeStorageAccountUrl
      filesystem: synapseDefaultContainerName
    }
    sqlAdministratorLogin: synapseSqlAdminUserName
    sqlAdministratorLoginPassword: synapseSqlAdminPassword
    //publicNetworkAccess: Post Deployment Script will disable public network access for vNet integrated deployments.
    managedResourceGroupName: synapseManagedRGName
    managedVirtualNetwork: (networkIsolationMode == 'vNet') ? 'default' : ''
    managedVirtualNetworkSettings: (networkIsolationMode == 'vNet')? {
      preventDataExfiltration:true
    }: null
    purviewConfiguration: (ctrlDeployPurview == true)? {
      purviewResourceId: purviewAccountID
    }: null
  }

  resource r_workspaceAADAdmin 'administrators' = {
    name:'activeDirectory'
    properties:{
      administratorType:'ActiveDirectory'
      tenantId: subscription().tenantId
      sid: UAMIPrincipalID
    }
  }


  //Dedicated SQL Pool
  resource r_sqlPool 'sqlPools' = if (ctrlDeploySynapseSQLPool == true){
    name: synapseDedicatedSQLPoolName
    location: resourceLocation
    sku:{
      name:synapseSQLPoolSKU
    }
    properties:{
      createMode:'Default'
      collation: 'SQL_Latin1_General_CP1_CI_AS'
    }
  }

  //Default Firewall Rules - Allow All Traffic
  resource r_synapseWorkspaceFirewallAllowAll 'firewallRules' = if (networkIsolationMode == 'default'){
    name: 'AllowAllNetworks'
    properties:{
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255'
    }
  }

  //Firewall Allow Azure Sevices
  //Required for Post-Deployment Scripts
  resource r_synapseWorkspaceFirewallAllowAzure 'firewallRules' = {
    name: 'AllowAllWindowsAzureIps'
    properties:{
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }

  //Set Synapse MSI as SQL Admin
  resource r_managedIdentitySqlControlSettings 'managedIdentitySqlControlSettings' = {
    name: 'default'
    properties:{
      grantSqlControlToManagedIdentity:{
        desiredState: 'Enabled'
      }
    }
  }

  //Spark Pool
  resource r_sparkPool 'bigDataPools' = if(ctrlDeploySynapseSparkPool == true){
    name: synapseSparkPoolName
    location: resourceLocation
    properties:{
      autoPause:{
        enabled:true
        delayInMinutes: 15
      }
      nodeSize: synapseSparkPoolNodeSize
      nodeSizeFamily:'MemoryOptimized'
      sparkVersion: '2.4'
      autoScale:{
        enabled:true
        minNodeCount: synapseSparkPoolMinNodeCount
        maxNodeCount: synapseSparkPoolMaxNodeCount
      }
    }
  }

  resource r_adxPool 'kustoPools@2021-06-01-preview' = if (ctrlDeploySynapseADXPool == true) {
    name: synapseADXPoolName
    location: resourceLocation
    sku: {
      capacity: 2
      name: 'Compute optimized'
      size: 'Extra small'
    }
    properties: {
      enablePurge: false
      workspaceUID: r_synapseWorkspace.properties.workspaceUID
      enableStreamingIngest: false
      optimizedAutoscale: {
        isEnabled: synapseADXPoolEnableAutoScale
        maximum: synapseADXPoolMaxSize
        minimum: synapseADXPoolMinSize
        version: 1
      }
    }

    resource r_adxDatabase 'databases' = {
      name: synapseADXDatabaseName
      kind: 'ReadWrite'
      location: resourceLocation
    }
  }
}


// Network Integration 
module m_vnetIntegration 'virtualNetworkIntegration.bicep' = if (ctrlDeployPrivateDNSZones == true && ctrlDeployVirtualNetwork != 'none') {
  name: 'configureSynapeNetwork'
  params: {
    location: resourceLocation
    virtualNetworkName: virtualNetworkName
    dnsZoneNames: [
        'privatelink.sql.azuresynapse.net'
        'privatelink.dev.azuresynapse.net'
        'privatelink.azuresynapse.net'
    ]
    privateEndpoints: [
      {
        name: 'synapseSQL-PE'
        subnetName: 'default'
        privateLinkServiceConnectionName: '${synapseWorkspaceName}-sql'
        privateLinkServiceId: r_synapseWorkspace.id
        groupIds: [
          'sql'
        ]
      }
      {
        name: 'synapseSQLServerless-PE'
        subnetName: 'default'
        privateLinkServiceConnectionName: '${synapseWorkspaceName}-sqlserverless'
        privateLinkServiceId: r_synapseWorkspace.id
        groupIds: [
          'SqlOnDemand'
        ]
      }
      {
        name: 'synapseDev-PE'
        subnetName: 'default'
        privateLinkServiceConnectionName: '${synapseWorkspaceName}-dev'
        privateLinkServiceId: r_synapseWorkspace.id
        groupIds: [
          'dev'
        ]
      }
    ]
  }
}

output synapseWorkspaceID                   string = r_synapseWorkspace.id
output synapseSQLDedicatedEndpoint          string = r_synapseWorkspace.properties.connectivityEndpoints.sql
output synapseSQLServerlessEndpoint         string = r_synapseWorkspace.properties.connectivityEndpoints.sqlOnDemand
output synapseWorkspaceSparkID              string = ctrlDeploySynapseSparkPool ? r_synapseWorkspace::r_sparkPool.id : ''
output synapseWorkspaceSparkName            string = ctrlDeploySynapseSparkPool ? r_synapseWorkspace::r_sparkPool.name : ''
output synapseWorkspaceIdentityPrincipalID  string = r_synapseWorkspace.identity.principalId
