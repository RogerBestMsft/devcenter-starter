import * as tools from '../../shared/tools.bicep'
targetScope = 'resourceGroup'

param config object

var devCenterName = tools.getResourceName(config.devCenterId)
var networks = contains(config, 'networks') ? config.networks : []
var networkLocations = union(map(networks, network => network.location), [])
var devBoxPools = contains(config, 'devBoxPools') ? config.devBoxPools : []

module devProject 'devProject.bicep' = {
  name: '${take(deployment().name, 36)}-devProject'
  scope: resourceGroup()
  params: {
    config: config
  }
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = [for (item, index) in networkLocations: {
  name: join([item, config.name, config.zone], '.')
  location: 'global'
}]

module network 'network.bicep' = [for (item, index) in networks: {
  name: '${take(deployment().name, 36)}-network-${format('{0:00}', index)}'
  scope: resourceGroup()
  dependsOn: [
    dnsZone
  ]
  params: {
    config: config
    network: item
    networkIndex: index 
  }
}]

module meshNetworks '../../shared/meshNetworks.bicep' = {
  name: '${take(deployment().name, 36)}-mesh-${uniqueString(string(networks))}'
  scope: subscription()
  dependsOn: [
    network
  ]
  params: {
    meshNetworkIds: [ for i in range(0, length(networks)) : network[i].outputs.network.id ]   
  }
}

module devBoxPool 'devBoxPool.bicep' = [for (item, index) in devBoxPools: {
  name: '${take(deployment().name, 36)}-devBoxPool-${format('{0:00}', index)}'
  scope: resourceGroup()
  dependsOn: [
    network
  ]
  params: {
    config: config
    pool: item
    poolIndex: index
  }
}]

module environmentTypes 'environmentTypes.bicep' = {
  name: '${take(deployment().name, 36)}-environmentTypes'
  scope: resourceGroup()
  dependsOn: [
    network
  ]
  params: {
    config: config
  }
}



