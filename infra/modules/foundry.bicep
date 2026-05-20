// =============================================================================
// foundry.bicep
// Provisions Azure AI Foundry: AIServices account + project + model deployment
// Target region: East US 2 (default) — this is the NEW Foundry resource
// (The existing Central US deployment is considered configuration drift)
// =============================================================================

@description('Name of the AIServices / Foundry account')
param accountName string

@description('Name of the Foundry project')
param projectName string

@description('Azure region — AIServices must be East US 2 per project requirements')
param location string = 'eastus2'

@description('Name of the model to deploy (e.g. gpt-4o)')
param modelName string = 'gpt-4o'

@description('Model version to deploy')
param modelVersion string = '2024-11-20'

@description('Token-per-minute capacity (in thousands) for the model deployment')
param capacity int = 10

@description('Resource tags')
param tags object = {}

// ---------------------------------------------------------------------------
// AIServices account (Foundry hub) with system-assigned identity
// ---------------------------------------------------------------------------
resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: accountName
  location: location
  tags: tags
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
    disableLocalAuth: false
    allowProjectManagement: true
    customSubDomainName: accountName
  }
}

// ---------------------------------------------------------------------------
// Foundry Project (child resource of the AIServices account)
// ---------------------------------------------------------------------------
resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  parent: foundryAccount
  name: projectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

// ---------------------------------------------------------------------------
// Model deployment — GlobalStandard for pay-as-you-go global routing
// ---------------------------------------------------------------------------
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-04-01-preview' = {
  parent: foundryAccount
  name: modelName
  sku: {
    name: 'GlobalStandard'
    capacity: capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
@description('Endpoint URL of the Foundry AIServices account')
output endpoint string = foundryAccount.properties.endpoint

@description('Resource ID of the Foundry AIServices account')
output accountId string = foundryAccount.id

@description('Resource ID of the Foundry project')
output projectId string = foundryProject.id

@description('System-assigned managed identity principal ID of the Foundry account')
output principalId string = foundryAccount.identity.principalId

@description('Name of the deployed model (used as the deployment name in API calls)')
output modelDeploymentName string = modelDeployment.name
