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
param workspaceName = 'mlpsegpoleappe8868312120'
param appInsightsName = 'appi-pole-app-eus2-mx01'

// ---------------------------------------------------------------------------
// Storage
// ---------------------------------------------------------------------------
param storageAccountName = 'stpoleappdemoeus2mx01'

// ---------------------------------------------------------------------------
// Key Vault
// ---------------------------------------------------------------------------
param kvName = 'kv-pole-app-eus2-mx01'

// ---------------------------------------------------------------------------
// Custom Vision (always deployed to East US — Azure limitation)
// ---------------------------------------------------------------------------
param customVisionTrainingName = 'visionpoleappeus2mx01'
param customVisionPredictionName = 'visionpoleappeus2mx01-Prediction'

// ---------------------------------------------------------------------------
// Computer Vision
// ---------------------------------------------------------------------------
param computerVisionName = 'vision-pole-app-eus2-mx02'

// ---------------------------------------------------------------------------
// Container Registry
// ---------------------------------------------------------------------------
param acrName = 'crpsegpoleappeus2mx01'

// ---------------------------------------------------------------------------
// Azure AI Foundry (NEW resource in East US 2 — distinct from Central US drift)
// ---------------------------------------------------------------------------
param foundryAccountName = 'foundry-pseg-pole-eus2'
param foundryProjectName = 'pole-verify-project'
param foundryModelName = 'gpt-4o'
param foundryModelVersion = '2024-11-20'
param foundryModelCapacity = 10

// ---------------------------------------------------------------------------
// Container App
// ---------------------------------------------------------------------------
param containerAppEnvName = 'cae-pseg-poleapp-eus2-mx01'
param containerAppName = 'aca-image-api-eus2-mx01'
param containerAppImageTag = 'latest' // Override with git SHA at deploy time

// ---------------------------------------------------------------------------
// Custom Vision runtime config
// Set these after first deploy once the Custom Vision project exists
// ---------------------------------------------------------------------------
param customVisionProjectId = '<set-post-deploy>'       // Custom Vision project GUID
param customVisionPublishedName = '<set-post-deploy>'   // Published iteration name (e.g. polecheck-20240101-1)
