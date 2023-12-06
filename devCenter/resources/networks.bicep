import * as tools from '../../shared/tools.bicep'
targetScope = 'resourceGroup'

param config object

var networks = contains(config, 'networks') ? config.networks : []
var networkRegions = union(map(networks, n => n.location), [])

module network 'network.bicep' = [for (item, index) in networks: {
  name: '${take(deployment().name, 36)}-network-${format('{0:00}', index)}'
  scope: resourceGroup()
  dependsOn: [
    networkZone
  ]
  params: {
    config: config
    network: item
    networkIndex: index 
  }
}]

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

module networkMesh '../../shared/meshNetworks.bicep' = if (length(networks) > 1) {
  name: '${take(deployment().name, 36)}-mesh-${uniqueString(string(networks))}'
  scope: subscription()
  params: {
    meshNetworkIds: [ for i in range(0, length(networks)): network[i].outputs.network.id ]
  }
}
