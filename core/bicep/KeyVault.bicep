@description('key vault name.')
param keyvault_name string

@description('key vault tags.')
param keyvault_tags object

@description('key vault location.')
param keyvault_location string = resourceGroup().location

@description('Id of the Azure AD tenant used for authenticating requests to the key vault resource.')
param keyvault_tenantid string

@description('Principal Id of the data factory resource.')
param datafactory_principalid string

@description('Data Factory Storage Account resource.')
param storageaccount_name string

@description('Connection String of the storage account resource.')
param storageaccount_connectionstring string

param storagebackup_name string

param backupstorage_connectionstring string

param SubnetId string

// Key Vault Resource

resource KeyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyvault_name
  location: keyvault_location
  tags: keyvault_tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: keyvault_tenantid
    enableSoftDelete: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: 90
    accessPolicies: [
      {
        tenantId: keyvault_tenantid
        objectId: datafactory_principalid
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
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
      virtualNetworkRules: [
        {
          id: SubnetId
          ignoreMissingVnetServiceEndpoint: true
        }
      ]
    }
  }
}

// Secret created with connection string to data lake storage account
resource Secret_DataLake 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  name: '${storageaccount_name}-connectionstring'
  parent: KeyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: storageaccount_connectionstring
  }
}

// Secret created with connection string to storagev2 backup account
resource Secret_Storage 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  name: '${storagebackup_name}-connectionstring'
  parent: KeyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: backupstorage_connectionstring
  }
}


//Outputs
output keyvault_uri string = KeyVault.properties.vaultUri
output keyvault_name string = KeyVault.name

