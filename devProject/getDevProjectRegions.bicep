import * as tools from 'tools.bicep'
targetScope = 'subscription'

param config object
param operationId string = newGuid()

module getDevCenterResource 'getDevCenterResource.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString('getDevCenterResource', operationId)}'
  scope: az.resourceGroup(split(config.devCenterId, '/')[2], split(config.devCenterId,'/')[4])
  params: {
    devCenterName: tools.getResourceName(config.devCenterId)
  }
}

module getDevProjectNetworks 'getDevProjectNetworks.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString('getDevProjectNetworks', operationId)}'
  scope: subscription()
  params: {
    config: config
  }
}

output regions array = union(
  [ getDevCenterResource.outputs.devCenterLocation ],
  map(getDevProjectNetworks.outputs.networks, network => tools.generalizeLocation(network.location)),
  map(getDevProjectNetworks.outputs.networks, network => tools.generalizeLocation(network.location)))

output primary string = getDevCenterResource.outputs.devCenterLocation
