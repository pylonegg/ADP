param (
    [string]$Environment,
    [string]$ResourceGroupName,
    [string]$StorageAccount
)


# Import CSV
$rbacAssignments = Join-Path -Path $PSScriptRoot -ChildPath "rbac_assignment.csv" | Import-Csv 

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
    write-host $StorageAccountResource

}