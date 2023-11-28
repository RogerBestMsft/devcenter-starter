import * as tools from '../shared/tools.bicep'
targetScope = 'subscription'

param config object

var removeProps = [ 'hubs', 'networks' ]
var configClean = toObject(filter(items(config), item => !contains(removeProps, item.key)), item => item.key, item => item.value)

module resolveHubs 'resolve/resolveHubs.bicep' = {
  name: '${take(deployment().name, 36)}-resolveHubs'
  scope: subscription()
  params: {
    config: config
  }
}

module resolveNetworks 'resolve/resolveNetworks.bicep' = {
  name: '${take(deployment().name, 36)}-resolveNetworks'
  scope: subscription()
  params: {
    config: config
  }
}

output config object = union(configClean, {
  resourceGroup: tools.getDCResourceGroupName(config.name)
  location: tools.generalizeLocation(config.location)
  hubs: union(resolveHubs.outputs.hubs, [])
  networks: union(resolveNetworks.outputs.networks, [])
})
