import * as tools from '../../shared/tools.bicep'
targetScope = 'subscription'

param config object
param hub object
param hubIndex int

var locationsMap = loadJsonContent('../data/locations.json')
var hubName = tools.getHUBNetworkName(hub.name, locationsMap, hub.location)

output hub object = union(hub, {
  name: hubName
  id: resourceId(subscription().subscriptionId, tools.getDCResourceGroupName(config.name), 'Microsoft.Network/virtualNetworks', hubName)
  location: tools.generalizeLocation(hub.location)
})
