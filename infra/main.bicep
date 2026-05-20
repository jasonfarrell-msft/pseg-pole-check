// =============================================================================
// main.bicep
// Orchestrates the full PSEG Pole Check infrastructure deployment
// Target scope: resource group (deploy with: az deployment group create ...)
//
// Deployment order:
//   1. monitoring     — Log Analytics + App Insights
//   2. storage        — Storage account + blob containers
//   3. keyvault       — Key Vault (principals added after containerapp)
//   4. customvision   — Custom Vision Training + Prediction (East US)
//   5. computervision — Azure Computer Vision
//   6. acr            — Azure Container Registry
//   7. foundry        — Azure AI Foundry AIServices + project + model
//   8. containerapp   — Container Apps Environment + Container App
//   9. rbac           — All remaining role assignments
// =============================================================================

targetScope = 'resourceGroup'

// ---------------------------------------------------------------------------
// Location parameters
// ---------------------------------------------------------------------------
@description('Primary Azure region for most resources')
param location string = 'eastus2'

// ---------------------------------------------------------------------------
// Monitoring
// ---------------------------------------------------------------------------
@description('Name of the Log Analytics workspace')
param workspaceName string

@description('Name of the Application Insights instance')
param appInsightsName string

// ---------------------------------------------------------------------------
// Storage
// ---------------------------------------------------------------------------
@description('Name of the storage account')
param storageAccountName string

// ---------------------------------------------------------------------------
// Key Vault
// ---------------------------------------------------------------------------
@description('Name of the Key Vault')
param kvName string

// ---------------------------------------------------------------------------
// Custom Vision (always East US — not configurable)
// ---------------------------------------------------------------------------
@description('Name of the Custom Vision Training account')
param customVisionTrainingName string

@description('Name of the Custom Vision Prediction account')
param customVisionPredictionName string

// ---------------------------------------------------------------------------
// Computer Vision
// ---------------------------------------------------------------------------
@description('Name of the Computer Vision account')
param computerVisionName string

// ---------------------------------------------------------------------------
// Container Registry
// ---------------------------------------------------------------------------
@description('Name of the Azure Container Registry')
param acrName string

// ---------------------------------------------------------------------------
// Azure AI Foundry
// ---------------------------------------------------------------------------
@description('Name of the Foundry AIServices account')
param foundryAccountName string

@description('Name of the Foundry project')
param foundryProjectName string

@description('Name of the model to deploy in Foundry')
param foundryModelName string = 'gpt-4o'

@description('Version of the model to deploy')
param foundryModelVersion string = '2024-11-20'

@description('TPM capacity for the model deployment (thousands)')
param foundryModelCapacity int = 10

// ---------------------------------------------------------------------------
// Container App
// ---------------------------------------------------------------------------
@description('Name of the Container Apps Environment')
param containerAppEnvName string

@description('Name of the Container App')
param containerAppName string

@description('Image tag to deploy (override with git SHA in CI/CD)')
param containerAppImageTag string = 'latest'

@description('Custom Vision prediction endpoint — passed from customvision module output')
param customVisionProjectId string = '<set-post-deploy>'

@description('Custom Vision published iteration name')
param customVisionPublishedName string = '<set-post-deploy>'

// ---------------------------------------------------------------------------
// Frontend App Service
// ---------------------------------------------------------------------------
@description('Name of the App Service Plan for the frontend')
param frontendPlanName string

@description('Name of the Web App for the frontend')
param frontendAppName string


@description('Environment label (dev, staging, prod)')
param environment string = 'dev'

var commonTags = {
  environment: environment
  project: 'pseg-pole-check'
  SecurityControl: 'Ignore'
}

// ===========================================================================
// 1. Monitoring — Log Analytics + Application Insights
// ===========================================================================
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    workspaceName: workspaceName
    appInsightsName: appInsightsName
    location: location
    tags: commonTags
  }
}

// ===========================================================================
// 2a. Frontend — App Service Plan + Web App (Vite SPA)
// ===========================================================================
module frontend 'modules/frontend.bicep' = {
  name: 'frontend'
  params: {
    planName: frontendPlanName
    appName: frontendAppName
    location: location
    tags: commonTags
  }
}

// ===========================================================================
// 2b. Storage — StorageV2, blob containers (no longer hosts static website)
// ===========================================================================
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    storageAccountName: storageAccountName
    location: location
    workspaceId: monitoring.outputs.workspaceId
    tags: commonTags
  }
}

// ===========================================================================
// 3. Key Vault — RBAC auth, soft-delete, purge protection
//    Principal list is populated after Container App identity is known;
//    the keyvault module also accepts an empty list (defaults to [])
// ===========================================================================
module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    kvName: kvName
    location: location
    tags: commonTags
  }
}

// ===========================================================================
// 4. Custom Vision — Training + Prediction (East US — hard requirement)
// ===========================================================================
module customVision 'modules/customvision.bicep' = {
  name: 'customvision'
  params: {
    trainingAccountName: customVisionTrainingName
    predictionAccountName: customVisionPredictionName
    tags: commonTags
  }
}

// ===========================================================================
// 5. Computer Vision — Azure AI Vision account
// ===========================================================================
module computerVision 'modules/computervision.bicep' = {
  name: 'computervision'
  params: {
    accountName: computerVisionName
    location: location
    tags: commonTags
  }
}

// ===========================================================================
// 6. Container Registry — Standard SKU, admin disabled
// ===========================================================================
module acr 'modules/acr.bicep' = {
  name: 'acr'
  params: {
    acrName: acrName
    location: location
    tags: commonTags
  }
}

// ===========================================================================
// 7. Azure AI Foundry — AIServices account + project + GPT-4o deployment
// ===========================================================================
module foundry 'modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    accountName: foundryAccountName
    projectName: foundryProjectName
    location: location
    modelName: foundryModelName
    modelVersion: foundryModelVersion
    capacity: foundryModelCapacity
    tags: commonTags
  }
}

// ===========================================================================
// 8. Container App — Pole Image API
// ===========================================================================
module containerApp 'modules/containerapp.bicep' = {
  name: 'containerapp'
  params: {
    envName: containerAppEnvName
    appName: containerAppName
    location: location
    workspaceId: monitoring.outputs.workspaceId
    workspaceCustomerId: monitoring.outputs.workspaceCustomerId
    acrLoginServer: acr.outputs.loginServer
    acrId: acr.outputs.acrId
    imageTag: containerAppImageTag
    storageAccountName: storageAccountName
    foundryEndpoint: foundry.outputs.endpoint
    foundryModelDeploymentName: foundry.outputs.modelDeploymentName
    customVisionEndpoint: customVision.outputs.predictionEndpoint
    customVisionProjectId: customVisionProjectId
    customVisionPublishedName: customVisionPublishedName
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    tags: commonTags
  }
}

// ===========================================================================
// 9. RBAC — all remaining role assignments (runs after identities are known)
// ===========================================================================
module rbac 'modules/rbac.bicep' = {
  name: 'rbac'
  params: {
    storageId: storage.outputs.storageResourceId
    acrId: acr.outputs.acrId
    kvId: keyvault.outputs.kvId
    foundryId: foundry.outputs.accountId
    customVisionPredictionId: customVision.outputs.predictionResourceId
    computerVisionId: computerVision.outputs.resourceId
    containerAppPrincipalId: containerApp.outputs.containerAppPrincipalId
    foundryPrincipalId: foundry.outputs.principalId
  }
}

// ===========================================================================
// Stack outputs
// ===========================================================================
@description('Frontend Web App URL')
output frontendUrl string = 'https://${frontend.outputs.defaultHostname}'

@description('Container App ingress URL for the Pole Image API')
output containerAppUrl string = 'https://${containerApp.outputs.containerAppFqdn}'

@description('Key Vault URI')
output keyVaultUri string = keyvault.outputs.kvUri

@description('Azure AI Foundry endpoint')
output foundryEndpoint string = foundry.outputs.endpoint

@description('Custom Vision Prediction endpoint')
output customVisionPredictionEndpoint string = customVision.outputs.predictionEndpoint
