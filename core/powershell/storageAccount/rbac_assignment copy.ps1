param (
    [string]$Environment,
    [string]$ResourceGroupName,
    [string]$StorageAccount
)


# Import CSV
$rbacAssignments = Import-Csv "rbac_assignment.csv"

# Loop through each row in the CSV
foreach ($assignment in $rbacAssignments) {
    $container  = $assignment.Container
    $user       = $assignment.User

    # Map roles
    if ($Environment -eq "dev" -and $assignment.Role -eq "Super User"){
        $role = " Advisory Custom Storage Container - Super User Dev"
    }
    elseif ($Environment -eq "dev" -and $assignment.Role -eq "Normal User"){
        $role = " Advisory Custom Storage Container - Nomal Dev"
    }
    elseif ($Environment -eq "prod" -and $assignment.Role -eq "Super User"){
        $role = "Advisory Custom Storage Container - Super Users"
    }
    elseif ($Environment -eq "prod" -and $assignment.Role -eq "Normal User"){
        $role = "Advisory Custom Storage Container - Normal Users"
    }
    else{
        $role = $assignment.Role
    }


    # Get Storage Account resource
    $StorageAccountResource = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccount

    if ($StorageAccountResource) {
        # Get Storage Account Context
        $storageContext = $StorageAccountResource.Context

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

        # Check if the role assignment already exists
        $existingRoleAssignment = Get-AzRoleAssignment -SignInName $user -Scope $containerResourceId -ErrorAction SilentlyContinue | Where-Object { $_.RoleDefinitionName -eq $role }

        if (-not $existingRoleAssignment) {
            # Assign role
            try {
                New-AzRoleAssignment -SignInName $user -RoleDefinitionName $role -Scope $containerResourceId -ErrorAction Stop
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