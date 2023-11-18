import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param location string = resourceGroup().location

var environmentTypes = map(items(contains(config, 'environmentTypes') ? config.environmentTypes : {}), 
  item => union(item.value, { name: item.key }))

module getDevCenterResource 'getDevCenterResource.bicep' = if (!empty(environmentTypes)) {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name)}'
  scope: az.resourceGroup(split(config.devCenterId, '/')[2], split(config.devCenterId,'/')[4])
  params: {
    devCenterName: tools.getResourceName(config.devCenterId)
  }
}
  
resource settingsStore 'Microsoft.AppConfiguration/configurationStores@2022-05-01' = if (!empty(environmentTypes)) {
  name: config.name
  location: location
  sku: {
    name: 'standard'
  }
  identity: {
    type: 'SystemAssigned'   
  }
  properties: {
    // disableLocalAuth: true
    publicNetworkAccess: 'Enabled'
  }
}

resource settingsVault 'Microsoft.KeyVault/vaults@2022-07-01' = if (!empty(environmentTypes)) {
  name: config.name
  location: location
  properties: {
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}
  
module environmentType 'environmentType.bicep' = [for (item, index) in environmentTypes: {
  name: '${take(deployment().name, 36)}-environmentType-${format('{0:00}', index)}'
  scope: resourceGroup()
  params: {
    config: config
    environmentType: item
    settingsStoreId: settingsStore.id
    settingsVaultId: settingsVault.id
  }
}]

module environmentInit 'environmentInit.bicep' = [for (item, index) in environmentTypes: {
  name: '${take(deployment().name, 36)}-environmentInit-${format('{0:00}', index)}'
  scope: subscription(item.subscription)
  params:  {
    config: config
    devCenterPrincipalId: getDevCenterResource.outputs.devCenterIdentity.principalId
  }
}]
