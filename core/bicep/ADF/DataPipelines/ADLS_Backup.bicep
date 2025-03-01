param backup_pipeline string
param copy_name string = 'ADLS_Copy_To_StorageV2'
param trigger_name string = 'Backup_Trigger'

param datalake_reference string
param storage_reference string
param Datafactory_Name string

// Data Factory
resource DataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: Datafactory_Name
}

// Back Up Data Lake storage to Storage V2 - ADF Data Pipeline 
resource Backup_DFPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: backup_pipeline
  parent: DataFactory
  properties: {
    activities: [
      {
        name: copy_name
        type: 'Copy'
        dependsOn: []
        policy: {
          timeout: '0.12:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        userProperties: [
          {
            name: 'Source'
            value: '//'
          }
          {
            name: 'Destination'
            value: 'archive//'
          }
        ]
        typeProperties: {
          source: {
            type: 'BinarySource'
            storeSettings: {
              type: 'AzureBlobFSReadSettings'
              recursive: true
              modifiedDatetimeStart: {
                value: '@pipeline().parameters.windowStart'
                type: 'Expression'
              }
              modifiedDatetimeEnd: {
                value: '@pipeline().parameters.windowEnd'
                type: 'Expression'
              }
              deleteFilesAfterCompletion: false
            }
            formatSettings: {
              type: 'BinaryReadSettings'
            }
          }
          sink: {
            type: 'BinarySink'
            storeSettings: {
              type: 'AzureBlobStorageWriteSettings'
              copyBehavior: 'PreserveHierarchy'
            }
          }
          enableStaging: false
          enableSkipIncompatibleRow: false
          skipErrorFile: {
            dataInconsistency: true
            fileMissing: true
          }
          validateDataConsistency: true
          logSettings: {
            enableCopyActivityLog: true
            copyActivityLogSettings: {
              logLevel: 'Warning'
              enableReliableLogging: true
            }
            logLocationSettings: {
              linkedServiceName: {
                referenceName: 'datalakelinkedService'
                type: 'LinkedServiceReference'
              }
              path: 'adf-pipeline-logs'
            }
          }
        }
        inputs: [
          {
            referenceName: datalake_reference
            type: 'DatasetReference'
          }
        ]
        outputs: [
          {
            referenceName: storage_reference
            type: 'DatasetReference'
            parameters: {
              containers: 'archive'
            }
          }
        ]
      }
    ]
    parameters: {
      windowStart: {
        type: 'String'
      }
      windowEnd: {
        type: 'String'
      }
    }
    annotations: []
  }
}

// ADF Pipeline Trigger

resource trigger 'Microsoft.DataFactory/factories/triggers@2018-06-01' = {
  parent: DataFactory
  name: trigger_name
  properties: {
    annotations: []
    pipeline: {
      pipelineReference: {
        referenceName: backup_pipeline
        type: 'PipelineReference'
      }
      parameters: {
        windowStart: '@trigger().outputs.windowStartTime'
        windowEnd: '@trigger().outputs.windowEndTime'
      }
    }
    type: 'TumblingWindowTrigger'
    typeProperties: {
      frequency: 'Hour'
      interval: 12
      startTime: '2024-02-09T20:00:00'
      delay: '00:00:00'
      maxConcurrency: 50
      retryPolicy: {
        intervalInSeconds: 30
      }
    }
  }
  dependsOn: [
    Backup_DFPipeline
  ]
}

// Outputs

output ADF_Backup_DataPipeline string = Backup_DFPipeline.name
