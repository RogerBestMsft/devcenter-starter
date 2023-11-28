import * as tools from '../../shared/tools.bicep'
targetScope = 'subscription'

param config object
param network object
param networkIndex int

var removeProps = [ 'hub' ]
var networkClean = toObject(filter(items(network), item => !contains(removeProps, item.key)), item => item.key, item => item.value)

var locationsMap = loadJsonContent('../data/locations.json')
var netName = tools.getDCNETNetworkName(network.name, locationsMap, network.location)
var hubName = tools.getHUBNetworkName(network.hub, locationsMap, network.location)

output network object = union(networkClean, {
  name: netName
  id: resourceId(subscription().subscriptionId, tools.getDCResourceGroupName(config.name), 'Microsoft.Network/virtualNetworks', netName)
  location: tools.generalizeLocation(network.location)
  hub: {
    name: hubName
    id: resourceId(subscription().subscriptionId, tools.getDCResourceGroupName(config.name), 'Microsoft.Network/virtualNetworks', hubName)
    location: tools.generalizeLocation(network.location)
  }
})

