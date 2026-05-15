// =============================================================================
// computervision.bicep
// Provisions an Azure Computer Vision (AI Vision) Cognitive Services account
// =============================================================================

@description('Name of the Computer Vision account')
param accountName string

@description('Azure region for the Computer Vision account')
param location string = resourceGroup().location

@description('Resource tags')
param tags object = {}

// ---------------------------------------------------------------------------
// Computer Vision account — S1 SKU for production workloads
// ---------------------------------------------------------------------------
resource computerVision 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: accountName
  location: location
  tags: tags
  kind: 'ComputerVision'
  sku: {
    name: 'S1'
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
@description('Endpoint URL for the Computer Vision account')
output endpoint string = computerVision.properties.endpoint

@description('Resource ID of the Computer Vision account')
output resourceId string = computerVision.id
