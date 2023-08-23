# Test function to test the new powershell durable function SDK

## Samples

### local.settings.json
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "", // this is the connection string to the storage account
    "FUNCTIONS_WORKER_RUNTIME_VERSION": "7.2",
    "FUNCTIONS_WORKER_RUNTIME": "powershell",
    "ldevorchestrationuksservicebus_SERVICEBUS": "", // this is the connection string to the service bus
    "TaskHubName": "testhub",
    "az__subscriptionName": "", // this is the name of the Azure subscription
    "config__managedIdentityClientId": "", // this is the client id of the managed identity
    "APPINSIGHTS_INSTRUMENTATIONKEY": "", // this is the instrumentation key of the application insights instance
    "localDev": "true", // this is used to determine if the function is running locally (auth with SPN) or in Azure (Auth with MUI)
    "devops__clientId": "", // this is the client id of the service principal
    "devops__clientSecret": "", // this is the client secret of the service principal
    "devops__tenantId": "", // this is the tenant id of the service principal
    "WEBSITE_OS": "linux",
    "ExternalDurablePowerShellSDK": "true"
  }
}
```