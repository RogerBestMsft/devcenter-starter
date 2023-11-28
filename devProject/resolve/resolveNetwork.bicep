import * as tools from '../../shared/tools.bicep'
targetScope = 'subscription'

param config object
param network object
param networkIndex int

var removeProps = [ 'hub' ]
var networkClean = toObject(filter(items(network), item => !contains(removeProps, item.key)), item => item.key, item => item.value)

var locationsMap = loadJsonContent('../data/locations.json')

module getDevCenterResource '../../shared/getDevCenterResource.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name, 'getDevCenterResource')}'
  scope: resourceGroup(split(config.devCenterId, '/')[2], split(config.devCenterId,'/')[4])
  params: {
    devCenterName: tools.getResourceName(config.devCenterId)
  }
}

module getNetworkResource '../../shared/getNetworkResource.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name, 'getNetworkResource')}'
  scope: resourceGroup(split(config.devCenterId, '/')[2], split(config.devCenterId,'/')[4])
  params: {
    networkName: tools.getHUBNetworkName(network.hub, locationsMap, network.location)
  }
}

module getFirewallResource '../../shared/getFirewallResource.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name, 'getFirewallResource')}'
  scope: resourceGroup(split(config.devCenterId, '/')[2], split(config.devCenterId,'/')[4])
  params: {
    firewallName: tools.getHUBNetworkName(network.hub, locationsMap, network.location)
  }
}

output network object = union(networkClean, {
  name: tools.getDPNETNetworkName(network.name, locationsMap, getNetworkResource.outputs.networkLocation)
  location: getNetworkResource.outputs.networkLocation
  hub : {
    name: getNetworkResource.outputs.networkName
    id: getNetworkResource.outputs.networkId
    location: getNetworkResource.outputs.networkLocation
  }
})
