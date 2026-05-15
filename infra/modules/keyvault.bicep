// =============================================================================
// keyvault.bicep
// Provisions an Azure Key Vault with RBAC auth mode, soft-delete, purge protection
// =============================================================================

@description('Name of the Key Vault')
param kvName string

@description('Azure region for the Key Vault')
param location string = resourceGroup().location

@description('Array of principal (object) IDs to grant Key Vault Secrets User role')
param principalIds array = []

@description('Resource tags')
param tags object = {}

// Well-known role definition GUID for Key Vault Secrets User
var kvSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

// ---------------------------------------------------------------------------
// Key Vault
// ---------------------------------------------------------------------------
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

// ---------------------------------------------------------------------------
// Placeholder VISION_KEY secret — actual value set post-deploy by CI/CD
// ---------------------------------------------------------------------------
resource visionKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'VISION-KEY'
  properties: {
    value: '' // Placeholder — operator/CI must populate this before the app can use Custom Vision
    attributes: {
      enabled: true
    }
  }
}

// ---------------------------------------------------------------------------
// Grant Key Vault Secrets User to each supplied principal
// ---------------------------------------------------------------------------
resource kvSecretsUserAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (principalId, i) in principalIds: {
    name: guid(keyVault.id, principalId, kvSecretsUserRoleId)
    scope: keyVault
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvSecretsUserRoleId)
      principalId: principalId
      principalType: 'ServicePrincipal'
    }
  }
]

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
@description('URI of the Key Vault')
output kvUri string = keyVault.properties.vaultUri

@description('Resource ID of the Key Vault')
output kvId string = keyVault.id

@description('Secret URI of the VISION_KEY placeholder secret')
output visionKeySecretUri string = visionKeySecret.properties.secretUri
