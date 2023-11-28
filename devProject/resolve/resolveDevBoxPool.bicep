import * as tools from '../../shared/tools.bicep'
targetScope = 'subscription'

param config object
param devBoxPool object
param devBoxPoolIndex int

var locationMap = loadJsonContent('../data/locations.json')

var devBoxPoolNetworks = flatten(map((contains(devBoxPool, 'networks') ? devBoxPool.networks : []), 
  net => map(empty((contains(net, 'locations') ? net.locations : [])) ? [ getDevCenterResource.outputs.devCenterLocation ] : net.locations, 
  loc => {
    name: net.scope == 'DevCenter' ? tools.getDCNETNetworkName(net.name, locationMap, loc)
                                   : tools.getDPNETNetworkName(net.name, locationMap, loc)
    id: net.scope == 'DevCenter' ? resourceId(split(config.devCenterId, '/')[2], split(config.devCenterId, '/')[4], 'Microsoft.Network/virtualNetworks', tools.getDCNETNetworkName(net.name, locationMap, loc))
                                 : resourceId(subscription().subscriptionId, tools.getDPResourceGroupName(config.name),  'Microsoft.Network/virtualNetworks', tools.getDPNETNetworkName(net.name, locationMap, loc))
    location: tools.generalizeLocation(loc)
  })))

module getDevCenterResource '../../shared/getDevCenterResource.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name, 'getDevCenterResource', string(devBoxPoolIndex))}'
  scope: resourceGroup(split(config.devCenterId, '/')[2], split(config.devCenterId,'/')[4])
  params: {
    devCenterName: tools.getResourceName(config.devCenterId)
  }
}

output devBoxPool object = union(devBoxPool, 
  {
    networks: union(devBoxPoolNetworks, [])
    administrator: contains(devBoxPool, 'administrator') ? bool(devBoxPool.administrator) : false
  }
)
