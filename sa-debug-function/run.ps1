using namespace System.Net
using namespace System.IO

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Information -MessageData "running debug function to determine modules and versions"

# Check access token expiration
if (!(Get-AzAccessToken -ErrorAction SilentlyContinue)) {
    $TokenExpiration = "Token Expired!!!"
}
else {
    $TokenExpiration = (Get-AzAccessToken -ErrorAction SilentlyContinue).ExpiresOn
}

if (Get-AzKeyVaultSecret -VaultName ($env:kv__subKeyVault) -Name "application-active-keyvaults" -AsPlainText -ErrorAction SilentlyContinue) {
    $KvAccess = "True"
}
else {
    $KvAccess = "False"
}

if ($env:localDev) {
    $testConnectionString = "Server=$($env:sql__azInstance),1433;Database=master;TrustServerCertificate=True;Connection Timeout=30;ConnectRetryCount=3;"
    $testConnection = New-Object Microsoft.Data.SqlClient.SqlConnection($testConnectionString)
    $testConnection.AccessToken = (Get-AzAccessToken -ResourceUrl 'https://database.windows.net' -ErrorAction Stop).Token
}
else {
    $testConnectionString = "Server=$($env:sql__azInstance),1433;Database=master;Authentication=Active Directory Managed Identity;User Id=$($env:config__managedIdentityClientId);Connection Timeout=60;ConnectRetryCount=3"
    $testConnection = New-Object Microsoft.Data.SqlClient.SqlConnection($testConnectionString)
}

try {
    $testConnection.Open()
    $sqlAccess = "True"
}
catch {
    $sqlAccess = "False"
}
finally {
    $testConnection.Close()
}

# Interact with query parameters or the body of the request.
# Get Loaded Assemblies
if ($Request.Query.Assemblies) {
    $assembliesAvailable = [System.AppDomain]::CurrentDomain.GetAssemblies()
    $null = $obj
    $obj = @()

    foreach ($curAssembly in $assembliesAvailable) {
        $temp = $curAssembly -split ','
        $assemblyProps = [ordered]@{
            name           = $temp[0]
            version        = ($temp[1] -split "=")[1]
            Culture        = ($temp[2] -split "=")[1]
            PublicKeyToken = ($temp[3] -split "=")[1]
            Location       = $curAssembly.Location
        }
        $obj += New-Object PsObject -Property $assemblyProps
    }
    $Assemblies = $obj | Sort-Object -Property Name
}

# Get Az Context Information
if ($Request.Query.ContextInfo) {
    $contextInfo = Get-AzContext -ListAvailable | Select-Object -Property Name, Account, Subscription, Tenant, TokenCache
}

$runningHostObj = [PSCustomObject](@{
        ProcessId      = $PID
        HostInstanceId = $HOST.InstanceId
        Runspace       = $HOST.Runspace.Name
        HomeLocation   = ($env:HOME)
        SessionToken   = $TokenExpiration
        KeyVaultAccess = $KvAccess
        SQLAccess      = $sqlAccess
    })

$poshTableVersion = $PSVersionTable | Select-Object PSVersion, PSEdition, Platform
$poshModules = Get-Module | Select-Object Name, Version, ModuleBase

$css = 'body{background:#252525;font:87.5%/1.5em Lato,sans-serif;padding:20px}table{border-spacing:1px;border-collapse:collapse;background:#F7F6F6;border-radius:6px;overflow:hidden;max-width:800px;width:100%;margin:0 auto;position:relative}td,th{padding-left:8px}thead tr{height:60px;background:#367AB1;color:#F5F6FA;font-size:1.2em;font-weight:700;text-transform:uppercase}tbody tr{height:48px;border-bottom:1px solid #367AB1;font-size:1em;&:last-child {;border:0}tr:nth-child(even){background-color:#E8E9E8}'

$htmlOut = html {
    head {
        style {
            $css
        }
    }
    Body {
        table {
            ConvertTo-PSHTMLTable -Object $runningHostObj -Properties ProcessId, Runspace, HostInstanceId, HomeLocation, SessionToken, KeyVaultAccess, SQLAccess
        }
        table {
            ConvertTo-PSHTMLTable -Object $poshTableVersion -Properties PSVersion, PSEdition, Platform
        }
        table {
            ConvertTo-PSHTMLTable -Object $poshModules -Properties Name, Version, ModuleBase
        }
        if ($Assemblies) {
            Table {
                ConvertTo-PSHTMLTable -Object $Assemblies -Properties name, version, Culture, PublicKeyToken, Location
            }
        }
        if ($contextInfo) {
            Table {
                ConvertTo-PSHTMLTable -Object $contextInfo -Properties Name, Account, Subscription, Tenant, TokenCache
            }
        }
    }
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        headers    = @{'content-type' = "text/html" }
        Body       = $htmlOut
    })
