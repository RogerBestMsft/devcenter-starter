import * as tools from '../../shared/tools.bicep'
targetScope = 'subscription'

param config object

var devBoxPools = map((contains(config, 'devBoxPools') ? items(config.devBoxPools) : []), 
                  item => union(item.value, { name: item.key }))

module resolveDevBoxPool 'resolveDevBoxPool.bicep' = [for (item, index) in devBoxPools: {
  name: '${take(deployment().name, 36)}-resolveDevBoxPool-${format('{0:00}', index)}'
  scope: subscription()
  params: {
    config: config
    devBoxPool: item
    devBoxPoolIndex: index
  }
}]

output devBoxPools array = [for i in range(0, length(devBoxPools)): resolveDevBoxPool[i].outputs.devBoxPool]
