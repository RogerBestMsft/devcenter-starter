import * as tools from '../../shared/tools.bicep'
targetScope = 'subscription'

param config object

var hubs = union(flatten(map(contains(config, 'hubs') ? items(config.hubs) : [], 
               item => map(item.value, val => union(val, { name: item.key })))), [])

module resolveHub 'resolveHub.bicep' = [for (item, index) in hubs: {
  name: '${take(deployment().name, 36)}-resolveHub-${format('{0:00}', index)}'
  scope: subscription()
  params: {
    config: config
    hub: item
    hubIndex: index
  }
}]

output hubs array = [for i in range(0, length(hubs)): resolveHub[i].outputs.hub]
