// =============================================================================
// rbac.bicep
// Centralised role assignments for all resource identities
//
// Role GUIDs (well-known, subscription-scoped):
//   Storage Blob Data Contributor : ba92f5b4-2d11-453d-a403-e96b0029c9fe
//   AcrPull                        : 7f951dda-4ed3-4680-a7ca-43fe172d538d
//   Key Vault Secrets User         : 4633458b-17de-408a-b874-0445c86b69e6
//   Cognitive Services User        : a97b65f3-24c7-4388-baec-2e87135dc908
//   Azure AI Developer             : 64702f94-c441-49e6-a78b-ef80e0188fee
//   Cognitive Services OpenAI Contrib: a001fd3d-188f-4b5d-821b-7da978bf7442
// =============================================================================

@description('Resource ID of the storage account')
param storageId string

@description('Resource ID of the Container Registry')
param acrId string

@description('Resource ID of the Key Vault')
param kvId string

@description('Resource ID of the Foundry AIServices account')
param foundryId string

@description('Resource ID of the Custom Vision Prediction account')
param customVisionPredictionId string

@description('Resource ID of the Computer Vision account')
param computerVisionId string

@description('Principal ID of the Container App system-assigned identity')
param containerAppPrincipalId string

@description('Principal ID of the Foundry AIServices system-assigned identity')
param foundryPrincipalId string

// ---------------------------------------------------------------------------
// Role definition IDs
// ---------------------------------------------------------------------------
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var kvSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'
var cognitiveServicesUserRoleId = 'a97b65f3-24c7-4388-baec-2e87135dc908'
var azureAiDeveloperRoleId = '64702f94-c441-49e6-a78b-ef80e0188fee'
var cognitiveServicesOpenAiContribRoleId = 'a001fd3d-188f-4b5d-821b-7da978bf7442'

// ---------------------------------------------------------------------------
// Container App → Storage Blob Data Contributor (reads/writes pole image blobs)
// ---------------------------------------------------------------------------
resource appStorageBlobContrib 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageId, containerAppPrincipalId, storageBlobDataContributorRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageBlobDataContributorRoleId
    )
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Container App → AcrPull (pull container images from the registry)
// ---------------------------------------------------------------------------
resource appAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, containerAppPrincipalId, acrPullRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Container App → Key Vault Secrets User (read VISION_KEY secret)
// ---------------------------------------------------------------------------
resource appKvSecretsUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kvId, containerAppPrincipalId, kvSecretsUserRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvSecretsUserRoleId)
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Container App → Cognitive Services User on Custom Vision Prediction
// (submit prediction requests)
// ---------------------------------------------------------------------------
resource appCustomVisionPredictionUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(customVisionPredictionId, containerAppPrincipalId, cognitiveServicesUserRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesUserRoleId)
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Container App → Azure AI Developer on Foundry
// (call chat completions, read project resources)
// ---------------------------------------------------------------------------
resource appFoundryAiDeveloper 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(foundryId, containerAppPrincipalId, azureAiDeveloperRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', azureAiDeveloperRoleId)
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Foundry → Cognitive Services OpenAI Contributor on Computer Vision
// (Foundry uses Computer Vision for multimodal/vision features)
// ---------------------------------------------------------------------------
resource foundryComputerVisionContrib 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(computerVisionId, foundryPrincipalId, cognitiveServicesOpenAiContribRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      cognitiveServicesOpenAiContribRoleId
    )
    principalId: foundryPrincipalId
    principalType: 'ServicePrincipal'
  }
}
