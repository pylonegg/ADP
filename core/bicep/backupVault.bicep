@description('Name of the Vault')
param vault_name string

@description('Change Vault Storage Type (not allowed if the vault has registered backups)')
@allowed([
  'LocallyRedundant'
  'GeoRedundant'
])
param vaultStorageRedundancy string

@description('Location for all resources.')
param location string

@description('BackUp / Rentention policy name')
param backupPolicy_name string = 'GoldPolicy'

@description('Retention duration in months')
@minValue(1)
@maxValue(11)
param retentionDays int = 11

@description('ISO 8601 for backup to vault')
param repeatingTime string = '03:30:00+00:00' 
param repeatingDate string = '2023-11-25' 

// Varibles 
@description('Rentention Duration')
var retentionDuration = 'P${retentionDays}M'

@description('Repeating Intervals')
var repeatingTimeInterval = 'R/${repeatingDate}T${repeatingTime}/P1D'

@description('Blob Servcies Data Source')
var dataSourceType = 'Microsoft.Storage/storageAccounts/blobServices'

// Back Up Vault 
resource Backup_Vault 'Microsoft.DataProtection/BackupVaults@2023-05-01' = {
  name: vault_name
  location: location
  identity: {
    type: 'systemAssigned'
  }
  properties: {
    storageSettings: [
      {
        datastoreType: 'VaultStore'
        type: vaultStorageRedundancy
      }
    ]
  }
}

// Backup policy
resource Backup_Policy 'Microsoft.DataProtection/backupVaults/backupPolicies@2021-01-01' = {
  parent: Backup_Vault
  name: backupPolicy_name
  properties: {
    objectType: 'BackupPolicy'
    policyRules: [
      {
        objectType: 'AzureRetentionRule'
        name: 'Default'
        isDefault: true
        lifecycles: [
          {
            sourceDataStore: {
              objectType: 'DataStoreInfoBase'
              dataStoreType: 'OperationalStore'
            }
            deleteAfter: {
              objectType: 'AbsoluteDeleteOption'
              duration: retentionDuration
            }
          }
        ]
      }
      {
        objectType: 'AzureRetentionRule'
        name: 'Default'
        isDefault: true
        lifecycles: [
          {
            sourceDataStore: {
              objectType: 'DataStoreInfoBase'
              dataStoreType: 'VaultStore'
            }
            deleteAfter: {
              objectType: 'AbsoluteDeleteOption'
              duration: 'P8Y'
            }
          }
        ]
      }
      // Vault 
      {
        objectType: 'AzureBackupRule'
        name: 'BackupDaily'
        backupParameters: {
          objectType: 'AzureBackupParams'
          backupType: 'Discrete'
        }
        trigger: {
          objectType: 'ScheduleBasedTriggerContext'
          schedule: {
            repeatingTimeIntervals: [
              repeatingTimeInterval
            ]
          }
          taggingCriteria: [
            {
              isDefault: true
              tagInfo: {
                tagName: 'Default'
              }
              taggingPriority: 99
            }
          ]
        }
        dataStore: {
          objectType: 'DataStoreInfoBase'
          dataStoreType: 'VaultStore'
        }
      }
    ]
    datasourceTypes: [
      dataSourceType
    ]

  }
}

// Outputs
output backupVaultID string = Backup_Vault.id
output backupVaultPrincipleID string = Backup_Vault.identity.principalId
output backupPolicy_ID string = Backup_Policy.id
output backupVaultName string = Backup_Vault.name
output backupPolicyName string = Backup_Policy.name
