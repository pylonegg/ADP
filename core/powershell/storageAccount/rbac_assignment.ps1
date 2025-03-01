param (
    [string]$Environment,
    [string]$ResourceGroupName,
    [string]$StorageAccount
)


# Import CSV
$rbacAssignments = Join-Path -Path $PSScriptRoot -ChildPath "../../../src/platform.operations/app/rbac_assignment.csv" | Import-Csv 

# Loop through each row in the CSV
foreach ($assignment in $rbacAssignments) {
    $container  = $assignment.Container
    $user       = $assignment.User
    $role       = $assignment.Role


    # Get Storage Account resource
    $StorageAccountResource = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccount
    write-host $StorageAccountResource

    if ($StorageAccountResource) {

        # Create a context object using Azure AD credentials, retrieve container
        $storageContext = New-AzStorageContext -StorageAccountName $StorageAccount -UseConnectedAccount


        # Check if the container exists, if not, create it
        $containerExists = Get-AzStorageContainer -Context $storageContext -Name $container -ErrorAction SilentlyContinue
        if (-not $containerExists) {
            New-AzStorageContainer -Context $storageContext -Name $container -PublicAccess Off
            Write-Host "Created container: $container in storage account: $StorageAccount"
        } else {
            Write-Host "Container $container already exists in storage account: $StorageAccount"
        }

        # Construct Container Resource ID for RBAC
        $StorageAccountId = $StorageAccountResource.Id
        $containerResourceId = "$StorageAccountId/blobServices/default/containers/$container"


        $ObjectId = (Get-AzADUser -UserPrincipalName "$user").Id
        # Check if the role assignment already exists
        $existingRoleAssignment = Get-AzRoleAssignment -ObjectId $ObjectId -Scope $containerResourceId -ErrorAction SilentlyContinue | Where-Object { $_.RoleDefinitionName -eq $role }

        if (-not $existingRoleAssignment) {
            # Assign role
            try {
                New-AzRoleAssignment -ObjectId $user -RoleDefinitionName $role -Scope $containerResourceId -ErrorAction Stop
                Write-Host "Successfully assigned $role to $user on $container in $StorageAccount"
            } catch {
                Write-Host "Error assigning $role to $user on $container in $StorageAccount : $_"
            }
        } else {
            Write-Host "Role $role is already assigned to $user on $container in $StorageAccount. Skipping..."
        }
    } else {
        Write-Host "Storage account $StorageAccount not found! Skipping..."
    }
}