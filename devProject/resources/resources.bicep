import * as tools from '../../shared/tools.bicep'
targetScope = 'resourceGroup'

param config object

var devCenterName = tools.getResourceName(config.devCenterId)
var networks = contains(config, 'networks') ? config.networks : []
var networkRegions = union(map(networks, network => network.location), [])
var devBoxPools = contains(config, 'devBoxPools') ? config.devBoxPools : []

module devProject 'devProject.bicep' = {
  name: '${take(deployment().name, 36)}-devProject'
  scope: resourceGroup()
  params: {
    config: config
  }
}

module network 'network.bicep' = [for (item, index) in networks: {
  name: '${take(deployment().name, 36)}-network-${format('{0:00}', index)}'
  scope: resourceGroup()
  params: {
    config: config
    network: item
    networkIndex: index 
  }
}]

module networkMesh '../../shared/meshNetworks.bicep' = if (length(networks) > 1) {
  name: '${take(deployment().name, 36)}-mesh-${uniqueString(string(networks))}'
  scope: subscription()
  dependsOn: [
    network
  ]
  params: {
    meshNetworkIds: [for i in range(0, length(networks)): network[i].outputs.network.id]
  }
}

resource networkZone 'Microsoft.Network/privateDnsZones@2020-06-01' = [for (item, index) in networkRegions: {
  name: join([item, config.zone], '.')
  location: 'global'
}]

module networkZoneRegister '../../shared/registerDnsZone.bicep' = [for (item, index) in networkRegions: {
  name: '${take(deployment().name, 36)}-zone-${item}'
  scope: resourceGroup()
  params: {
    config: config
    zone: networkZone[index].name
    autoNetworkIds: [for i in range(0, length(networks)): network[i].outputs.network.location == item ? network[i].outputs.network.id : '']
    linkNetworkIds: [for i in range(0, length(networks)): network[i].outputs.network.location != item ? network[i].outputs.network.id : '']
  }
}]


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



