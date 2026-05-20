// =============================================================================
// main.bicepparam
// Parameter values for the PSEG Pole Check infrastructure
//
// Names match the existing production resources in rg-pseg-pole-app-eus2-mx01
// so that a first deploy against that RG will reconcile rather than duplicate.
//
// Override containerAppImageTag with a git SHA in CI/CD:
//   az deployment group create ... --parameters containerAppImageTag=$(git rev-parse --short HEAD)
//
// Post-deploy operator steps:
//   1. Set the VISION-KEY secret in Key Vault to the Custom Vision API key
//   2. Set customVisionProjectId to the Custom Vision project GUID
//   3. Set customVisionPublishedName to the active published iteration name
// =============================================================================

using './main.bicep'

// ---------------------------------------------------------------------------
// Environment
// ---------------------------------------------------------------------------
param environment = 'dev'
param location = 'eastus2'

// ---------------------------------------------------------------------------
// Monitoring
// ---------------------------------------------------------------------------
param workspaceName = 'mlpsegpoleappeus2px01'
param appInsightsName = 'appi-pole-app-eus2-px01'

// ---------------------------------------------------------------------------
// Storage
// ---------------------------------------------------------------------------
param storageAccountName = 'stpoleappdemoeus2px01'

// ---------------------------------------------------------------------------
// Key Vault
// ---------------------------------------------------------------------------
param kvName = 'kv-pole-app-eus2-px01'

// ---------------------------------------------------------------------------
// Custom Vision (always deployed to East US — Azure limitation)
// ---------------------------------------------------------------------------
param customVisionTrainingName = 'visionpoleappeus2px01'
param customVisionPredictionName = 'visionpoleappeus2px01-Prediction'

// ---------------------------------------------------------------------------
// Computer Vision
// ---------------------------------------------------------------------------
param computerVisionName = 'vision-pole-app-eus2-px01'

// ---------------------------------------------------------------------------
// Container Registry
// ---------------------------------------------------------------------------
param acrName = 'crpsegpoleappeus2px01'

// ---------------------------------------------------------------------------
// Azure AI Foundry (deployed alongside everything else in the same RG)
// ---------------------------------------------------------------------------
param foundryAccountName = 'foundry-pseg-pole-eus2-px01'
param foundryProjectName = 'pole-verify-project'
param foundryModelName = 'gpt-4.1'
param foundryModelVersion = '2025-04-14'
param foundryModelCapacity = 10

// ---------------------------------------------------------------------------
// Container App
// ---------------------------------------------------------------------------
param containerAppEnvName = 'cae-pseg-poleapp-eus2-px01'
param containerAppName = 'aca-image-api-eus2-px01'
param containerAppImageTag = 'latest' // Override with git SHA at deploy time

// ---------------------------------------------------------------------------
// Frontend App Service
// ---------------------------------------------------------------------------
param frontendPlanName = 'asp-pole-frontend-eus2-px01'
param frontendAppName = 'app-pole-frontend-eus2-px01'

// ---------------------------------------------------------------------------
// Custom Vision runtime config
// Set these after first deploy once the Custom Vision project exists
// ---------------------------------------------------------------------------
param customVisionProjectId = '6de5df3f-8ad0-4573-ac39-3c476df7b865'
param customVisionPublishedName = 'polecheck-20260520-01'
