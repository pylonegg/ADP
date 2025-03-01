# ---------------------------------------------------------------
# Author: Chi Adiukwu
# Initial Creation: 28/01/2025 
# LastUpdated: 29/01/2025
# Description: Calls Powershell module/functions (Databricks)
# ---------------------------------------------------------------

param (
    [string]$Environment,
    [string]$DataFactoryName,
    [string]$ResourceGroupName,
    [string]$triggerStatus
)

Join-Path -Path $PSScriptRoot -ChildPath "../../core/powershell/datafactory-utils.psm1" | Import-Module

# --------------------------------------------------------------------------------------------------
# Create a function in core/powershell/datafactory-utils.psm1 and call it here!
# --------------------------------------------------------------------------------------------------

Start-DataFactoryTriggers -dataFactoryName $DataFactoryName -resourceGroup $ResourceGroupName -environment $Environment -triggerStatus $triggerStatus