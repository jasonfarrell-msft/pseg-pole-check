// =============================================================================
// acr.bicep
// Provisions Azure Container Registry (Standard SKU, admin account disabled)
// Container Apps pull via managed identity — AcrPull role assigned in rbac.bicep
// =============================================================================

@description('Name of the Azure Container Registry')
param acrName string

@description('Azure region for the registry')
param location string = resourceGroup().location

@description('Resource tags')
param tags object = {}

// ---------------------------------------------------------------------------
// Container Registry
// ---------------------------------------------------------------------------
resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: false // Admin disabled — pull via AcrPull RBAC on managed identity
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
@description('Login server FQDN for the registry (e.g. myacr.azurecr.io)')
output loginServer string = acr.properties.loginServer

@description('Resource ID of the Container Registry')
output acrId string = acr.id
