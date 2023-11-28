import * as tools from '../../shared/tools.bicep'
targetScope = 'subscription'

param config object

var networks = flatten(map(contains(config, 'networks') ? items(config.networks) : [], 
               item => map(item.value, val => union(val, { name: item.key }))))

module resolveNetwork 'resolveNetwork.bicep' = [for (item, index) in networks: {
  name: '${take(deployment().name, 36)}-resolveNetwork-${format('{0:00}', index)}'
  scope: subscription()
  params: {
    config: config
    network: item
    networkIndex: index
  }
}]

output networks array = [for i in range(0, length(networks)): resolveNetwork[i].outputs.network]
