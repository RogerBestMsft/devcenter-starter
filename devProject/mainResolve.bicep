import * as tools from '../shared/tools.bicep'
targetScope = 'subscription'

param config object

var removeProps = [ 'networks', 'devBoxPools' ]
var configClean = toObject(filter(items(config), item => !contains(removeProps, item.key)), item => item.key, item => item.value)

module getDevCenterResource '../shared/getDevCenterResource.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name, 'getDevCenterResource')}'
  scope: resourceGroup(split(config.devCenterId, '/')[2], split(config.devCenterId,'/')[4])
  params: {
    devCenterName: tools.getResourceName(config.devCenterId)
  }
}

module resolveNetworks 'resolve/resolveNetworks.bicep' = {
  name: '${take(deployment().name, 36)}-resolveNetworks'
  scope: subscription()
  params: {
    config: config
  }
}

module resolveDevBoxPools 'resolve/resolveDevBoxPools.bicep' = {
  name: '${take(deployment().name, 36)}-resolveDevBoxPools'
  scope: subscription()
  params: {
    config: config
  }
}

output config object = union(configClean, {
  resourceGroup: tools.getDPResourceGroupName(config.name)
  location: getDevCenterResource.outputs.devCenterLocation
  networks: union(resolveNetworks.outputs.networks, [])
  devBoxPools: union(resolveDevBoxPools.outputs.devBoxPools, [])
})
