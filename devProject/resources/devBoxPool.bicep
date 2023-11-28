import * as tools from '../../shared/tools.bicep'
targetScope = 'resourceGroup'

param config object
param pool object
param poolIndex int

var devCenterName = tools.getResourceName(config.devCenterId)
var networks = contains(pool, 'networks') ? pool.networks : []

var networkConnectionNames = map(map(networks, 
  network => tools.replaceResourceProvider(network.id, 'Microsoft.DevCenter/networkConnections')), 
  id => ((toLower(tools.getSubscriptionId(id)) == toLower(subscription().subscriptionId) && toLower(tools.getResourceGroupName(id)) == toLower(config.resourceGroup))) ? tools.getDPNetworkAttachmentName(config.name, id) : tools.getDCNetworkAttachmentName(devCenterName, id)
)

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' existing = {
  name: config.name
}

resource devBoxPool 'Microsoft.DevCenter/projects/pools@2022-11-11-preview' = [for (item, index) in networks: {
  name: '${pool.name}-${join(skip(split(item.name, '-'), 1), '-')}'
  location: config.location
  parent: project
  properties: {    
    devBoxDefinitionName: pool.definition
    networkConnectionName: networkConnectionNames[index]
    licenseType: 'Windows_Client'
    localAdministrator: pool.administrator ? 'Enabled' : 'Disabled'
  }
}]

