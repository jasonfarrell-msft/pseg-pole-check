// =============================================================================
// customvision.bicep
// Provisions Custom Vision Training + Prediction Cognitive Services accounts
//
// IMPORTANT: Custom Vision is NOT available in East US 2.
// Both accounts are HARD-CODED to East US (eastus). Do not change this.
// =============================================================================

@description('Name for the Custom Vision Training account')
param trainingAccountName string

@description('Name for the Custom Vision Prediction account')
param predictionAccountName string

@description('Resource tags')
param tags object = {}

// Custom Vision is only available in specific regions — East US is the required region.
// Do NOT parameterise this location; it must stay as eastus.
var customVisionLocation = 'eastus'

// ---------------------------------------------------------------------------
// Custom Vision Training account
// ---------------------------------------------------------------------------
resource trainingAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: trainingAccountName
  location: customVisionLocation
  tags: tags
  kind: 'CustomVision.Training'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// ---------------------------------------------------------------------------
// Custom Vision Prediction account
// ---------------------------------------------------------------------------
resource predictionAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: predictionAccountName
  location: customVisionLocation
  tags: tags
  kind: 'CustomVision.Prediction'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
@description('Endpoint URL for the Custom Vision Training account')
output trainingEndpoint string = trainingAccount.properties.endpoint

@description('Resource ID of the Custom Vision Training account')
output trainingResourceId string = trainingAccount.id

@description('Endpoint URL for the Custom Vision Prediction account')
output predictionEndpoint string = predictionAccount.properties.endpoint

@description('Resource ID of the Custom Vision Prediction account')
output predictionResourceId string = predictionAccount.id
