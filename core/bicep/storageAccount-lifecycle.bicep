param storageaccount_name string

resource StorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: storageaccount_name
}

resource Lifecycle_Manage 'Microsoft.Storage/storageAccounts/managementPolicies@2023-01-01' = {
  name: 'default'
  parent: StorageAccount
  properties: {
    policy: {
      rules: [
        {
          definition: {
            actions: {
              baseBlob: {
                tierToArchive: {
                  daysAfterLastTierChangeGreaterThan: 7
                  daysAfterModificationGreaterThan: 90
                }
                tierToCool: {
                  daysAfterLastAccessTimeGreaterThan: 30
                }
              }
            }
            filters: {
              blobTypes: [
                'blockBlob'
              ]
            }
          }
          enabled: true
          name: 'LifecycleMain'
          type: 'Lifecycle'
        }
      ]
    }
  }
}
