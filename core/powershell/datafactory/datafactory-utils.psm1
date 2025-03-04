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
        [string]$environment,
        [string]$triggerStatus
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
        if ($triggerStatus.ToLower() -eq "stopped") {
            Write-Host "Pipeline library parameter state is `"Stopped`". Stopping trigger: $triggerName"
            Stop-AzDataFactoryV2Trigger -Force -ResourceGroupName $resourceGroup -DataFactoryName $dataFactoryName -Name $triggerName
        }
        else {
            Write-Host "Pipeline library parameter state is not `"Stopped`". Starting trigger: $triggerName"
            Start-AzDataFactoryV2Trigger -Force -ResourceGroupName $resourceGroup -DataFactoryName $dataFactoryName -Name $triggerName
        }
    }
}