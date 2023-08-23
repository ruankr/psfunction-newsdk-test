Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
Import-Module AzureFunctions.PowerShell.Durable.SDK -ErrorAction Stop
try {
    # Authenticate with Azure PowerShell using SPN or MUI.
    if ($env:localDev) {
        # Logon to Azure (SPN)
        Disable-AzContextAutosave -Scope Process | Out-Null
        $spnSecret = $env:devops__clientSecret | ConvertTo-SecureString -AsPlainText -Force
        $spnCredential = New-Object -TypeName System.Management.Automation.PSCredential($env:devops__clientId, $spnSecret)
        Connect-AzAccount -Tenant $env:devops__tenantId -Subscription ($env:az__subscriptionName) -Credential $spnCredential -ServicePrincipal -ErrorAction Stop | Out-Null
        Write-Information -MessageData "connected function to azure using spn"
    }
    else {
        # Logon to Azure (MUI)
        Disable-AzContextAutosave -Scope Process | Out-Null
        Connect-AzAccount -Identity -AccountId ($env:config__managedIdentityClientId) -Subscription ($env:az__subscriptionName) -ErrorAction Stop | Out-Null
        Write-Information -MessageData "connected function to azure using mui"
    }

}
catch {
    throw $_
}

Write-Information -MessageData "profile load completed"