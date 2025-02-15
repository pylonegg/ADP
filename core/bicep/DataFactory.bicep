@description('data factory name.')
param datafactory_name string

@description('data factory location.')
param datafactory_location string

@description('Environment name.')
param environment string

param managed_vnet_name string = 'default'

param integrated_runtime_name string 
param repositoryName string
param repositoryType string
param repositoryAccountName string
param repositoryProjectName string
param repositoryCollaborationBranch string
param repositoryRootFolder string


// Variables
@description('Data Factory Repo Link')
var properties = environment == 'Development' ? {
  repoConfiguration: {
    repositoryName: repositoryName
    accountName: repositoryAccountName
    projectName: repositoryProjectName
    collaborationBranch: repositoryCollaborationBranch
    rootFolder: repositoryRootFolder
    type: repositoryType
  }
  publicNetworkAccess: 'Disabled'
} : {}

// Data Factory Resource
resource DataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: datafactory_name
  location: datafactory_location
  tags: resourceGroup().tags
  identity: {
    type: 'SystemAssigned'
  }  
  properties: properties

}

// // Managed Virtual Network 
// resource Managed_Virtual_Network 'Microsoft.DataFactory/factories/managedVirtualNetworks@2018-06-01' = {
//   name: managed_vnet_name
//   parent: DataFactory
//   properties: {}
// }
// 
// // Managed Integrated Runtime
// resource Integrated_Runtime 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
//   name: integrated_runtime_name
//   parent: DataFactory
//   properties: {
//     description: 'Managed Private Virtual Network Integrated Runtime'
//     type: 'Managed'
//     typeProperties: {
//       computeProperties: {
//         location: 'West Europe'
//         dataFlowProperties: {
//           computeType: 'General'
//           coreCount: 8
//           timeToLive: 10
//           cleanup: false
//           customProperties: []
//         }
//         pipelineExternalComputeScaleProperties: {
//           timeToLive: 60
//           numberOfPipelineNodes: 1
//           numberOfExternalNodes: 1
//         }
//         managedVirtualNetwork: {
//           type: 'ManagedVirtualNetworkReference'
//           referenceName: managed_vnet_name
//         }
//       }
//     }
//   }
//   dependsOn: [
//     Managed_Virtual_Network
//   ]
// }
// 
// // Outputs
// output datafactoryID string = DataFactory.id
// output datafactoryPrincipleID  string = DataFactory.identity.principalId
// output df_name string = DataFactory.name
// output integrated_runtime_name string = Integrated_Runtime.name
