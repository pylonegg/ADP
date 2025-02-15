#=============================================================================
# Author: Chi Adiukwu
# Initial Creation: 04/02/2025 
# LastUpdated: 11/01/2025
# Description: Powershell module for Data Factory deployment
#=====================================|=======================================

function Start-DataFactoryTriggers {
    param (
        [string]$dataFactoryName,
        [string]$resourceGroup,
        [string]$environment
    )
    
    Write-Host "`n============================= GET ADF TRIGGERS =============================="
    $triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $resourceGroup -DataFactoryName $dataFactoryName

    if (-not $triggers){
        Write-Host "No triggers found."
        return
    }
    else {
        Write-Host "Triggers found:"
        foreach ($trigger in $triggers) {
            $triggerName = $trigger.Name
            Write-Host "    - $triggerName"
        }
    }

    Write-Host "`n============================ START ADF TRIGGERS ============================="
    foreach ($trigger in $triggers) {
        $triggerName = $trigger.Name
        if ($environment -eq "dev") {
            Write-Host "Skipping dev trigger: $triggerName"
        }
        else {
            Write-Host "Starting trigger: $triggerName"
            Start-AzDataFactoryV2Trigger -Force -ResourceGroupName $resourceGroup -DataFactoryName $dataFactoryName -Name $triggerName
        }
    }
}