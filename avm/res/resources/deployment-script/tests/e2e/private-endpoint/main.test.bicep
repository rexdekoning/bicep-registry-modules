targetScope = 'subscription'

metadata name = 'Using Private Endpoint'
metadata description = 'This instance deploys the module with access to a private endpoint.'

// ========== //
// Parameters //
// ========== //

@description('Optional. The name of the resource group to deploy for testing purposes.')
@maxLength(90)
param resourceGroupName string = 'avm-${namePrefix}-resources.deploymentscripts-${serviceShort}-rg'

@description('Optional. The location to deploy resources to.')
param resourceLocation string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'rdspe'

@description('Optional. A token to inject into the name of each resource.')
param namePrefix string = '#_namePrefix_#'

// ============ //
// Dependencies //
// ============ //

// General resources
// =================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: resourceLocation
}

module nestedDependencies 'dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, resourceLocation)}-nestedDependencies'
  params: {
    managedIdentityName: 'dep-${namePrefix}-msi-${serviceShort}'
    storageAccountName: 'dep${namePrefix}sa${serviceShort}'
    virtualNetworkName: 'dep-${namePrefix}-vnet-${serviceShort}'
    privateEndpointName: 'dep-${namePrefix}-pe-${serviceShort}'
    location: resourceLocation
  }
}

// ============== //
// Test Execution //
// ============== //

module testDeployment '../../../main.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, resourceLocation)}-test-${serviceShort}'
  params: {
    name: '${namePrefix}${serviceShort}001'
    location: resourceLocation
    azCliVersion: '2.52.0'
    kind: 'AzureCLI'
    retentionInterval: 'P1D'
    cleanupPreference: 'Always'
    subnetResourceIds: [
      nestedDependencies.outputs.subnetResourceId
    ]
    managedIdentities: {
      userAssignedResourceIds: [
        nestedDependencies.outputs.managedIdentityResourceId
      ]
    }
    timeout: 'PT1H'
    runOnce: true
    scriptContent: 'echo \'AVM Deployment Script test!\''
    storageAccountResourceId: nestedDependencies.outputs.storageAccountResourceId
  }
}
