param vNetID string
param vNetName string
param subnetID string

param resourceLocation string
param ctrlDeployPrivateDNSZones bool
param ctrlDeployPurview bool
param ctrlDeployStreaming bool
param ctrlStreamIngestionService string

//Key Vault Params
param keyVaultID string
param keyVaultName string

//Synapse Analytics Params
param synapsePrivateLinkHubName string

param dataLakeAccountID string
param dataLakeAccountName string

//Purview Params
param purviewAccountID string
param purviewAccountName string
param purviewManagedStorageAccountID string
param purviewManagedEventHubNamespaceID string

//Event Hub Namespace Params
param eventHubNamespaceID string
param eventHubNamespaceName string

//IoT Hub Params
param iotHubID string
param iotHubName string

var environmentStorageDNS = environment().suffixes.storage

//==================================================================================================================
var dnsZones = [
    'privatelink.dfs.${environmentStorageDNS}'
    'privatelink.queue.${environmentStorageDNS}'
    'privatelink.vaultcore.azure.net'
    'privatelink.servicebus.windows.net'
    'privatelink.purview.azure.com'
    'privatelink.purview.azure.com'
    'privatelink.purviewstudio.azure.com'
    'privatelink.azure-devices.net'
]

//==================================================================================================================

//Azure Synapse Private Link Hub
resource r_synapsePrivateLinkhub 'Microsoft.Synapse/privateLinkHubs@2021-03-01' = {
  name: synapsePrivateLinkHubName
  location:resourceLocation
}

var privateEndpoints = [
  {
    condition: (ctrlDeployStreaming == true && ctrlStreamIngestionService == 'iothub')
    name: 'IotHubPrivateLink'
    groupId: 'iotHub'
    privateEndpoitName: '${iotHubName}-iotHub'
    privateLinkServiceId: iotHubID
    dnsZoneName: 'privatelink-azure-devices-net'
    privateDnsZoneId: r_privateDNSZoneIoTHub.id
  }
  {
    condition: true
    name: 'KeyVaultPrivateLink'
    groupId: 'vault'
    privateEndpoitName: keyVaultName
    privateLinkServiceId: keyVaultID
    dnsZoneName: 'privatelink-vaultcore-azure-net'
    privateDnsZoneId: r_privateDNSZoneKeyVault.id
  }
  {
    condition: true
    name: 'DataLakePrivateLinkDFS'
    groupId: 'dfs'
    privateEndpoitName: '${dataLakeAccountName}-dfs'
    privateLinkServiceId: dataLakeAccountID
    dnsZoneName: 'privatelink-dfs-core-windows-net'
    privateDnsZoneId: r_privateDNSZoneStorageDFS.id
  }
  {
    condition: (ctrlDeployPurview == true)
    name: 'PurviewBlobPrivateLink'
    groupId: 'blob'
    privateEndpoitName: '${purviewAccountName}-blob'
    privateLinkServiceId: purviewManagedStorageAccountID
    dnsZoneName: 'privatelink-blob-core-windows-net'
    privateDnsZoneId: r_privateDNSZoneBlob.id
  }
  {
    condition: (ctrlDeployPurview == true)
    name: 'PurviewQueuePrivateLink'
    groupId: 'queue'
    privateEndpoitName: '${purviewAccountName}-queue'
    privateLinkServiceId: purviewManagedStorageAccountID
    dnsZoneName: 'privatelink-queue-core-windows-net'
    privateDnsZoneId: r_privateDNSZoneStorageQueue.id
  }
  {
    condition: (ctrlDeployPurview == true)
    name: 'PurviewEventHubPrivateLink'
    groupId: 'namespace'
    privateEndpoitName: '${purviewAccountName}-namespace'
    privateLinkServiceId: purviewManagedEventHubNamespaceID
    dnsZoneName: 'privatelink-servicebus-windows-net'
    privateDnsZoneId: r_privateDNSZoneServiceBus.id
  }
  {
    condition: (ctrlDeployPurview == true)
    name: 'PurviewAccountPrivateLink'
    groupId: 'account'
    privateEndpoitName: '${purviewAccountName}-account'
    privateLinkServiceId: purviewAccountID
    dnsZoneName: 'privatelink-purview-azure-com-account'
    privateDnsZoneId: r_privateDNSZonePurviewAccount.id
  }
  {
    condition: (ctrlDeployPurview == true)
    name: 'PurviewPortalPrivateLink'
    groupId: 'portal'
    privateEndpoitName: '${purviewAccountName}-portal'
    privateLinkServiceId: purviewAccountID
    dnsZoneName: 'privatelink-purview-azure-com-portal'
    privateDnsZoneId: r_privateDNSZonePurviewPortal.id
  }
  {
    condition: (ctrlDeployStreaming == true && ctrlStreamIngestionService == 'eventhub')
    name: 'EventHubPrivateLink'
    groupId: 'namespace'
    privateEndpoitName: '${eventHubNamespaceName}-namespace'
    privateLinkServiceId: eventHubNamespaceID
    dnsZoneName: 'privatelink-servicebus-windows-net'
    privateDnsZoneId: r_privateDNSZoneServiceBus.id
  }
]

