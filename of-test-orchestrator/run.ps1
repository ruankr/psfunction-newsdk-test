using namespace System.Net

param($Context)

$ErrorActionPreference = 'Stop'

$finalOutput = @{
    Success = @()
    Failed  = @()
}

$output = @()

$parallelTasks =
foreach ($property in $Context.Input.psobject.properties.name) {
    # invoke the activity function
    Invoke-DurableActivity -FunctionName "af-test-activity1" -Input $Context.Input.$property -NoWait
}

try {
    # schedule the tasks. If they all succeed, they will be collected in the $output variable
    $output = Wait-DurableTask -Task $parallelTasks
    foreach ($out in $output) {
        $finalOutput.Success += $out
    }
}
catch {
    # if we're here, then at least one of the $parallelTasks failed.
    # now we need to collect tasks individually, protecting against exceptions
    foreach ($task in $parallelTasks) {
        # for each scheduled sub task
        try {
            # try to get the result of the task. If the result is an exception, it will throw it
            $result = Get-DurableTaskResult -Task $task
            $finalOutput.Success += $result
        }
        catch {
            # if we're here, the result is an exception, so we opt to add its error message to the list.
            $failedItem = $_.Exception.Message.Split("[").Split("]")[1]
            $finalOutput.Failed += "[$($failedItem)] Failed"
        }
    }
}

# Set orchestrator custom status
if ($finalOutput.Failed.Count -gt 0 -and $finalOutput.Success.Count -gt 0) {
    Set-DurableCustomStatus -CustomStatus "Orchestration Part Failed"
}
elseif ($finalOutput.Failed.Count -eq 0 -and $finalOutput.Success.Count -gt 0) {
    Set-DurableCustomStatus -CustomStatus "Orchestration Succeeded"
}
elseif ($finalOutput.Failed.Count -gt 0 -and $finalOutput.Success.Count -eq 0) {
    Set-DurableCustomStatus -CustomStatus "Orchestration Failed"
}

$finalOutput