// =============================================================================
// containerapp.bicep
// Provisions Container Apps Environment + Container App for the Pole Image API
// System-assigned managed identity; image pulled from ACR via AcrPull RBAC
// VISION_KEY is read from Key Vault via secretRef
// =============================================================================

@description('Name of the Container Apps Environment')
param envName string

@description('Name of the Container App')
param appName string

@description('Azure region')
param location string = resourceGroup().location

@description('Resource ID of the Log Analytics workspace for environment telemetry')
param workspaceId string

@description('Customer ID of the Log Analytics workspace')
param workspaceCustomerId string

@description('Login server of the ACR (e.g. myacr.azurecr.io)')
param acrLoginServer string

@description('Resource ID of the ACR (used for AcrPull role assignment)')
param acrId string

@description('Container image name (without registry prefix or tag)')
param imageName string = 'image-api'

@description('Image tag to deploy — override with git SHA in CI/CD')
param imageTag string = 'latest'

@description('Name for the container within the app')
param containerName string = 'image-api'

@description('Storage account name passed to the app via environment variable')
param storageAccountName string

@description('Azure AI Foundry endpoint URL')
param foundryEndpoint string

@description('Name of the model deployment to call in Foundry')
param foundryModelDeploymentName string

@description('Custom Vision prediction endpoint URL')
param customVisionEndpoint string

@description('Custom Vision project GUID')
param customVisionProjectId string

@description('Custom Vision published iteration name (e.g. polecheck-20240101-1)')
param customVisionPublishedName string

@description('Key Vault URI (e.g. https://kv-name.vault.azure.net/)')
param kvUri string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Resource tags')
param tags object = {}

// ---------------------------------------------------------------------------
// Log Analytics workspace — reference only (created in monitoring module)
// ---------------------------------------------------------------------------
resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: last(split(workspaceId, '/'))
}

// ---------------------------------------------------------------------------
// Container Apps Environment — Consumption tier, linked to Log Analytics
// ---------------------------------------------------------------------------
resource containerAppsEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: envName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: workspaceCustomerId
        sharedKey: workspace.listKeys().primarySharedKey
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Container App — system-assigned identity, ingress on port 8080
// Secret: VISION-KEY sourced from Key Vault (no listKeys, no hardcoding)
// ---------------------------------------------------------------------------
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppsEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
      }
      registries: [
        {
          server: acrLoginServer
          identity: 'system'
        }
      ]
      secrets: [
        {
          // Key Vault reference — Container Apps fetches the secret using the app's managed identity
          name: 'vision-key'
          keyVaultUrl: '${kvUri}secrets/VISION-KEY'
          identity: 'system'
        }
      ]
    }
    template: {
      containers: [
        {
          name: containerName
          image: '${acrLoginServer}/${imageName}:${imageTag}'
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          env: [
            {
              name: 'StorageAccountName'
              value: storageAccountName
            }
            {
              name: 'FoundryEndpoint'
              value: foundryEndpoint
            }
            {
              name: 'FoundryModelDeploymentName'
              value: foundryModelDeploymentName
            }
            {
              name: 'VISION_ENDPOINT'
              value: customVisionEndpoint
            }
            {
              name: 'CUSTOM_VISION_PROJECT_ID'
              value: customVisionProjectId
            }
            {
              name: 'CUSTOM_VISION_PUBLISHED_NAME'
              value: customVisionPublishedName
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsightsConnectionString
            }
            {
              name: 'VISION_KEY'
              secretRef: 'vision-key'
            }
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Production'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
    }
  }
}

// ---------------------------------------------------------------------------
// AcrPull role assignment for the container app's system-assigned identity
// ---------------------------------------------------------------------------
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, containerApp.id, acrPullRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
@description('Fully-qualified domain name of the Container App ingress')
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn

@description('Resource ID of the Container App')
output containerAppId string = containerApp.id

@description('System-assigned managed identity principal ID of the Container App')
output containerAppPrincipalId string = containerApp.identity.principalId
