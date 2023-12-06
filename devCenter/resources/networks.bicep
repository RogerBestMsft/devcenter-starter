import * as tools from '../../shared/tools.bicep'
targetScope = 'resourceGroup'

param config object

var networks = contains(config, 'networks') ? config.networks : []
var networkLocations = union(map(networks, n => n.location), [])

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = [for (item, index) in networkLocations: {
  name: join([item, config.zone], '.')
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

module networkMesh '../../shared/meshNetworks.bicep' = if (length(networks) > 1) {
  name: '${take(deployment().name, 36)}-mesh-${uniqueString(string(networks))}'
  scope: subscription()
  params: {
    meshNetworkIds: [ for i in range(0, length(networks)): network[i].outputs.networkId ]
  }
}
