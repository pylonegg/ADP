// 1
@description('Array of actions for the roleDefinition')
param actions1 array = [
  'Microsoft.Storage/storageAccounts/blobServices/containers/read'
  'Microsoft.Storage/storageAccounts/blobServices/containers/write'
  'Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action'
]

@description('Array of notActions for the roleDefinition')
param notActions1 array = [
]

@description('Array of dataActions for the roleDefinition')
param dataActions1 array = [
  'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete'
  'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/move/action'
]

param notDataActions1 array = [
  'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write'
  'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'
]

// 2
@description('Array of actions for the roleDefinition')
param actions2 array = [
  'Microsoft.Storage/storageAccounts/blobServices/containers/read'
  'Microsoft.Storage/storageAccounts/blobServices/containers/write'
  'Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action'
]

@description('Array of notActions for the roleDefinition')
param notActions2 array = [
  'Microsoft.Storage/storageAccounts/blobServices/containers/delete'
]

@description('Array of dataActions for the roleDefinition')
param dataActions2 array = [
  'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete'
  'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'
  'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write'
  'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/move/action'
  'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/add/action'
]

@description('Array of notDataActions for the roleDefinition')
param notDataActions2 array = [
  'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/modifyPermissions/action'
]

// 3
param actions3 array = [
  'Microsoft.Storage/storageAccounts/blobServices/containers/*'
  'Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action'
]

param notActions3 array = [
  'Microsoft.Storage/storageAccounts/blobServices/containers/delete'
]

param dataActions3 array = [
  'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/*'
]

param notDataActions3 array = [
]

@description(' role definition')
param roleName1 string = 'Advisory Custom Storage Account - All Users'
param roleName2 string = 'Advisory Custom Storage Container - Normal Users'
param roleName3 string = 'Advisory Custom Storage Container - Super Users'

@description('Description of the roles')
param roleDescription1 string = 'Custom Advisory ADLS Stprage Account Role'
param roleDescription2 string = 'Custom Advisory ADLS Container Role - For Normal Users'
param roleDescription3 string = 'Custom Advisory ADLS Container Role - For Super Users'

@description('ADLS')
param StorageAccountName string

// Variables
var roleDefName1 = guid(subscription().id, string(actions1), string(notActions1))
var roleDefName2 = guid(subscription().id, string(actions2), string(notDataActions2))
var roleDefName3 = guid(subscription().id, string(actions3), string(notDataActions3))
var assignableScopes = '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Storage/storageAccounts/${StorageAccountName}'

// Storage Account Level Custom Role
resource roleDef1 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: roleDefName1
  properties: {
    roleName: roleName1
    description: roleDescription1
    type: 'customRole'
    permissions: [
      {
        actions: actions1
        notActions: notActions1
        dataActions: dataActions1
        notDataActions: notDataActions1
      }
    ]
    assignableScopes: [
      assignableScopes
    ]
  }
}

// Storage Container Level Custom Role - Normal
resource roleDef2 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: roleDefName2
  properties: {
    roleName: roleName2
    description: roleDescription2
    type: 'customRole'
    permissions: [
      {
        actions: actions2
        notActions: notActions2
        dataActions: dataActions2
        notDataActions: notDataActions2
      }
    ]
    assignableScopes: [
      assignableScopes
    ]
  }
  dependsOn: [
    roleDef1
  ]
}

// Storage Container Level Custom Role - Super User
resource roleDef3 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: roleDefName3
  properties: {
    roleName: roleName3
    description: roleDescription3
    type: 'customRole'
    permissions: [
      {
        actions: actions3
        notActions: notActions3
        dataActions: dataActions3
        notDataActions: notDataActions3
      }
    ]
    assignableScopes: [
      assignableScopes
    ]
  }
  dependsOn: [
    roleDef2
  ]
}

// Outputs
output custom_role_1 string = roleDef1.name
output custom_role_2 string = roleDef2.name
output custom_role_3 string = roleDef3.name
