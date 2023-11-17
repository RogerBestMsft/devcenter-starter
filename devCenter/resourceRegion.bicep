import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param location string

var networks = filter(map((contains(config, 'networks') ? config.networks : []), 
  network => union(network, { location: tools.generalizeLocation(contains(network, 'location') ? network.location : config.location) })),
  network => network.location == tools.generalizeLocation(location))

var networkHubs = filter(networks, network => network.type == 'Hub')
var networkNets = empty(networkHubs) ? [] : filter(networks, network => network.type == 'Net')

module policy 'policy.bicep' = {
  name: '${take(deployment().name, 36)}-fwp-${location}'
  scope: resourceGroup()
  params: {
    config: config
    location: location
  }
}

module networkHub 'networkHubs.bicep' = [ for (item, index) in networkHubs: {
  name: '${take(deployment().name, 36)}-hub-${location}-${format('{0:00}', index)}'
  scope: resourceGroup()
  params: {
    config: config
    network: item
    networkIndex: index
    regionPolicyId: policy.outputs.firewallPolicyId
  }
}]

module networkNet 'networkNets.bicep' = [ for (item, index) in networkNets: {
  name: '${take(deployment().name, 36)}-net-${location}-${format('{0:00}', index)}'
  scope: resourceGroup()
  params: {
    config: config
    network: item
    networkIndex: index
    networkHubs: [for i in range(0, length(networkHubs)): networkHub[i].outputs.network]
  }
}]

output networkHubs array = [ for i in range(0, length(networkHubs)): networkHub[i].outputs.network ]
output networkNets array = [ for i in range(0, length(networkNets)): networkNet[i].outputs.network ]
