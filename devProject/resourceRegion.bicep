// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param location string
param networks array

module network 'network.bicep' = [ for (item, index) in networks: {
  name: '${take(deployment().name, 36)}-net-${location}${format('{0:00}', index)}'
  scope: resourceGroup()
  params: {
    config: config
    network: item
    networkIndex: index
  }
}]

output networks array = [for i in range(0, length(networks)): network[i].outputs.network]
