import * as tools from 'tools.bicep'
targetScope = 'subscription'

param config object

module resolveDevCenterResource '_resolveDevCenterResource.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString('resolveDevCenterResource', string(config))}'
  scope: az.resourceGroup(split(config.devCenterId, '/')[2], split(config.devCenterId,'/')[4])
  params: {
    devCenterName: tools.getResourceName(config.devCenterId)
  }
}

module initialize 'initialize.bicep' = {
  name: '${take(deployment().name, 36)}-initialize'
  scope: subscription()
  params: {
    config: config
    location: resolveDevCenterResource.outputs.devCenterLocation
  }
}



