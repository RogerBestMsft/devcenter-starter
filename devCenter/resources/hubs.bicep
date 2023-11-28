import * as tools from '../../shared/tools.bicep'
targetScope = 'resourceGroup'

param config object

var locationsMap = loadJsonContent('../data/locations.json')

var hubs = contains(config, 'hubs') ? config.hubs : []
var regions = union(map(hubs, hub => hub.location), [])

module policy 'policy.bicep' = [for (item, index) in regions: {
  name: '${take(deployment().name, 36)}-policy-${format('{0:00}', index)}'
  scope: resourceGroup()
  params: {
    config: config
    location: item
  }
}]

module hub 'hub.bicep' = [for (item, index) in hubs: {
  name: '${take(deployment().name, 36)}-hub-${format('{0:00}', index)}'
  scope: resourceGroup()
  params: {
    config: config
    hub: item
    hubIndex: index 
    policyId: policy[indexOf(regions, item.location)].outputs.policyId
  }
}]

