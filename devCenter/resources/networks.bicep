import * as tools from '../../shared/tools.bicep'
targetScope = 'resourceGroup'

param config object

var networks = contains(config, 'networks') ? config.networks : []

module network 'network.bicep' = [for (item, index) in networks: {
  name: '${take(deployment().name, 36)}-network-${format('{0:00}', index)}'
  scope: resourceGroup()
  params: {
    config: config
    network: item
    networkIndex: index 
  }
}]
