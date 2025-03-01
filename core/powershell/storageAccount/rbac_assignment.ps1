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

}