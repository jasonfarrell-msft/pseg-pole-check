// =============================================================================
// frontend.bicep
// Provisions an App Service Plan + Web App to host the Vite SPA frontend
// =============================================================================

@description('Name of the App Service Plan')
param planName string

@description('Name of the Web App')
param appName string

@description('Azure region')
param location string = resourceGroup().location

@description('Resource tags')
param tags object = {}

// ---------------------------------------------------------------------------
// App Service Plan — S1 Standard Linux
// ---------------------------------------------------------------------------
resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
  properties: {
    reserved: true // required for Linux
  }
}

// ---------------------------------------------------------------------------
// Web App — static Node-served SPA (serve via npx serve or similar)
// Using a minimal staticfiles approach: set to serve from /home/site/wwwroot
// ---------------------------------------------------------------------------
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  tags: tags
  kind: 'app,linux'
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      alwaysOn: true
      appSettings: [
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
      // No custom appCommandLine — Oryx runs npm install then npm start (from package.json)
    }
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
@description('Default hostname of the web app')
output defaultHostname string = webApp.properties.defaultHostName

@description('Resource ID of the web app')
output webAppId string = webApp.id

@description('Name of the web app')
output webAppName string = webApp.name
