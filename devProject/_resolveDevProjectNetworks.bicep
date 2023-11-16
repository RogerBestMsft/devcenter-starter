import * as tools from 'tools.bicep'
targetScope = 'subscription'

param config object
param operationId string = newGuid()

var networks = contains(config, 'networks') ? config.networks : []
  
module resolveNetworkResource '_resolveNetworkResource.bicep' = [for network in networks: if (contains(network, 'hubName')) {
  name: '${take(deployment().name, 36)}-${uniqueString('resolveNetworkResource', operationId, string(network))}'
  scope: resourceGroup(split(config.devCenterId, '/')[2], split(config.devCenterId,'/')[4])
  params: {
    networkName: network.hubName
  }
}]

module resolveDevCenterResource '_resolveDevCenterResource.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString('resolveDevCenterResource', operationId)}'
  scope: resourceGroup(split(config.devCenterId, '/')[2], split(config.devCenterId,'/')[4])
  params: {
    devCenterName: tools.getResourceName(config.devCenterId)
  }
}

output networks array = [for (network, index) in networks: union(network, { _key: guid(string(network)) }, contains(network, 'hubName') ? { 
  hubId: resolveNetworkResource[index].outputs.networkId
  location: tools.generalizeLocation(contains(network, 'location') ? network.location : resolveNetworkResource[index].outputs.networkLocation)
} : {
  location: tools.generalizeLocation(contains(network, 'location') ? network.location : resolveDevCenterResource.outputs.devCenterLocation)
})]

