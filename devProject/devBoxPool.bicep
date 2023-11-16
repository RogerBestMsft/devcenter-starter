import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param pool object

var locationMap = loadJsonContent('./data/locations.json')
var networks = contains(pool, 'networks') ? pool.networks : []
var networkLocations = map(networks, network => tools.getLocationDisplayName(locationMap, network.location, true))

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' existing = {
  name: config.name
}

resource devBoxPool 'Microsoft.DevCenter/projects/pools@2022-11-11-preview' = [for (item, index) in networks: {
  name: '${pool.name}-${networkLocations[index]}-${format('{0:00}', index)}'
  location: pool.location
  parent: project
  properties: {    
    devBoxDefinitionName: pool.definition
    networkConnectionName: item.name
    licenseType: 'Windows_Client'
    localAdministrator: contains(pool, 'administrator') ? (pool.administrator ? 'Enabled' : 'Disabled') : 'Disabled'
  }
}]
