
param Datafactory_Name string
param ADLS_Name string
param SA_Name string
param Vault_Name string

resource workspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' existing = {
  name: 'DefaultWorkspace-d4c85d92-b8ed-4621-9fd3-c457e3e6d83a-WEU'
}

// Data Factory 
resource DataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: Datafactory_Name
}

// Data Lake 
resource DataLake 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: ADLS_Name
}

// Storage V2 
resource StorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: SA_Name
}

resource Backup_Vault 'Microsoft.DataProtection/BackupVaults@2023-05-01' existing = {
  name: Vault_Name
}


resource DF_Diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnosticsName_DF'
  scope: DataFactory
  properties: {
    logs: [
      {
        category: 'ActivityRuns'
        enabled: true
      }
      {
        category: 'PipelineRuns'
        enabled: true
      }
      {
        category: 'TriggerRuns'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    storageAccountId: StorageAccount.id
    workspaceId: workspace.id
  }
}

resource ADLS_Diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnosticsName_ADLS'
  scope: DataLake
  properties: {
    logs: [
      {
        category: 'ActivityRuns'
        enabled: true
      }
      {
        category: 'PipelineRuns'
        enabled: true
      }
      {
        category: 'TriggerRuns'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    storageAccountId: StorageAccount.id
    workspaceId: workspace.id
  }
}

resource SA_Diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnosticsName_SA'
  scope: StorageAccount
  properties: {
    logs: [
      {
        category: 'ActivityRuns'
        enabled: true
      }
      {
        category: 'PipelineRuns'
        enabled: true
      }
      {
        category: 'TriggerRuns'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    storageAccountId: StorageAccount.id
    workspaceId: workspace.id
  }
}

resource Vault_Diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnosticsName_Vault'
  scope: Backup_Vault
  properties: {
    logs: [
      {
        category: 'ActivityRuns'
        enabled: true
      }
      {
        category: 'PipelineRuns'
        enabled: true
      }
      {
        category: 'TriggerRuns'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    storageAccountId: StorageAccount.id
    workspaceId: workspace.id
  }
}


//validate module
