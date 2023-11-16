// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param location string

var networks = filter(map((contains(config, 'networks') ? config.networks : []), 
  network => union(network, { location: toLower(replace(contains(network, 'location') ? network.location : config.location, ' ', '')) })),
  network => network.location == toLower(replace(location, ' ', '')))

module policy 'policy.bicep' = {
  name: '${take(deployment().name, 36)}_fwp_${location}'
  scope: resourceGroup()
  params: {
    config: config
    location: location
  }
}

module network 'network.bicep' = [ for (item, index) in networks: {
  name: '${take(deployment().name, 36)}-net-${location}${format('{0:00}', index)}'
  scope: resourceGroup()
  params: {
    config: config
    network: item
    networkIndex: index
    regionPolicyId: policy.outputs.firewallPolicyId
  }
}]
