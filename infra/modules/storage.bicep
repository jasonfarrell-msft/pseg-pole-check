// =============================================================================
// storage.bicep
// Provisions Storage Account with blob containers and static website hosting
// =============================================================================

@description('Name of the storage account')
param storageAccountName string

@description('Azure region for the storage account')
param location string = resourceGroup().location

@description('Resource ID of the Log Analytics workspace for diagnostics')
param workspaceId string

@description('Resource tags')
param tags object = {}

// ---------------------------------------------------------------------------
// Storage Account — Standard LRS StorageV2 with HTTPS enforced
// ---------------------------------------------------------------------------
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    // Public network access must be enabled for the static website endpoint
    // to serve the frontend SPA. Blob-level public access is still blocked above.
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

// ---------------------------------------------------------------------------
// Blob service — enables container management and soft-delete
// ---------------------------------------------------------------------------
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// ---------------------------------------------------------------------------
// Application blob containers
// uploads   — incoming pole images (30 blobs in production)
// images    — processed/labelled images (17 blobs in production)
// mltable   — AzureML mltable artefacts (4 blobs in production)
// revisions — revisioned analysis outputs
// snapshots — point-in-time snapshots
// (AzureML blobstore containers are created by AzureML, not Bicep)
// ---------------------------------------------------------------------------
var blobContainerNames = ['uploads', 'images', 'mltable', 'revisions', 'snapshots']

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [
  for containerName in blobContainerNames: {
    parent: blobService
    name: containerName
    properties: {
      publicAccess: 'None'
    }
  }
]

// ---------------------------------------------------------------------------
// Diagnostic settings — send storage metrics to Log Analytics
// ---------------------------------------------------------------------------
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${storageAccountName}'
  scope: storageAccount
  properties: {
    workspaceId: workspaceId
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
@description('Name of the storage account')
output storageAccountName string = storageAccount.name

@description('Resource ID of the storage account')
output storageResourceId string = storageAccount.id

@description('Primary blob endpoint')
output primaryEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Static website primary endpoint')
output staticWebEndpoint string = storageAccount.properties.primaryEndpoints.web
