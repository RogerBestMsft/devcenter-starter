// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param locations array
param networks array

module resourceRegion 'resourceRegion.bicep' = [for (item, index) in locations: {
  name: '${take(deployment().name, 36)}-region-${item}'
  scope: resourceGroup()
  params: {
    config: config
    location: item
    networks: filter(networks, network => network.location == item)
  }
}]

output networks array = [for network in networks: first(filter(resourceRegion[indexOf(locations, network.location)].outputs.networks, n => n._key == network._key))]
