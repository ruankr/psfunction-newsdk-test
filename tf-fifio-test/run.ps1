param([string] $SbMsg, $TriggerMetadata)
$ErrorActionPreference = "Stop"

<#
Service bus message received:
{
  "TestFilter": {
    "version": "1.0.0",
    "environment": "testEnv",
    "itemName": [
      "test1",
      "test2",
      "test3",
      "test4",
      "test5"
    ],
    "appComponent": "testcomponent",
    "application": "testApp"
  }
}
#>

# Declare 5 cities to be randomly picked later
$city = @("London", "Paris", "New York", "Tokyo", "Sydney")

# Create a hashtable the orchestrator could use to iterate over
foreach ($item in $TriggerMetadata.TestFilter.itemName) {
    $hashtableout += @{
        $item = @{
            city     = $city | Get-Random
            itemName = $item
        }
    }
}

# Start the orchestration
$InstanceId = Start-DurableOrchestration -FunctionName "of-test-orchestrator" -Input $hashtableout -ErrorAction Stop
Write-Host "Started orchestration with ID = '$InstanceId'"