
resource Delete_Lock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'DontDelete'
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevent deletion of the Resource Group'
  }
}

//Outputs
output ResourceGroup_Lock string = Delete_Lock.name
