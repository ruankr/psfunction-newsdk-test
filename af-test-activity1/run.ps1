param($afItems)

try {
    $ErrorActionPreference = 'Stop'

    $actStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $ranSecs = Get-Random -Minimum 10 -Maximum 60


    if ($($afItems.itemName) -eq "test-item-32") { throw "$($afItems.itemName) - Is failing" }
    elseif ($($afItems.itemName) -eq "test-item-41") { throw "$($afItems.itemName) also failed" }
    elseif ($($afItems.itemName) -eq "test-item-50") { Start-Sleep -Seconds 190 }
    else { Start-Sleep -Seconds $ranSecs }

    # Finalise outputs
    $actStopwatch.stop()
    [decimal]$elapsedSecods = $actStopwatch.Elapsed.TotalMinutes
    $actTotalTime = "{0:N2}" -f $elapsedSecods
    Write-Information -MessageData "$($afItems.itemName) completed in [$actTotalTime]"

    return "[$($afItems.itemName)] Completed. runTime($($actTotalTime))"

}
catch {
    $errItem = $_.Exception
    $errLine = $_.InvocationInfo.ScriptLineNumber
    $errMsg = $errItem.Message

    $actStopwatch.stop()
    [decimal]$elapsedSecods = $actStopwatch.Elapsed.TotalMinutes
    $actTotalTime = "{0:N2}" -f $elapsedSecods

    throw $("[$($afItems.itemName)] errMsg($($errMsg)) errLn($($errLine)) duration($($actTotalTime))")
}