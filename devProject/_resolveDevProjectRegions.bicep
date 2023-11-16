import * as tools from 'tools.bicep'
targetScope = 'subscription'

param config object
param operationId string = newGuid()

module resolveDevCenterResource '_resolveDevCenterResource.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString('resolveDevCenterResource', operationId)}'
  scope: az.resourceGroup(split(config.devCenterId, '/')[2], split(config.devCenterId,'/')[4])
  params: {
    devCenterName: tools.getResourceName(config.devCenterId)
  }
}

module resolveDevProjectNetworks '_resolveDevProjectNetworks.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString('resolveDevProjectNetworks', operationId)}'
  scope: subscription()
  params: {
    config: config
  }
}

output regions array = union(
  [ resolveDevCenterResource.outputs.devCenterLocation ],
  map(resolveDevProjectNetworks.outputs.networks, network => tools.generalizeLocation(network.location)),
  map(resolveDevProjectNetworks.outputs.networks, network => tools.generalizeLocation(network.location)))

output primary string = resolveDevCenterResource.outputs.devCenterLocation
