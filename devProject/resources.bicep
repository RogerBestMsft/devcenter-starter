// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object

module getDevProjectRegions 'getDevProjectRegions.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString('getDevProjectRegions', string(config))}'
  scope: subscription()
  params: {
    config: config
  }
}

module getDevProjectNetworks 'getDevProjectNetworks.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString('getDevProjectNetworks', string(config))}'
  scope: subscription()
  params: {
    config: config
  }
}

module resourceRegions 'resourceRegions.bicep' = {
  name: '${take(deployment().name, 36)}-regions'
  scope: resourceGroup()
  params: {
    config: config
    locations: getDevProjectRegions.outputs.regions
    networks: getDevProjectNetworks.outputs.networks
  }
}

module devProject 'devProject.bicep' = {
  name: '${take(deployment().name, 36)}-devProject'
  scope: resourceGroup()
  params: {
    config: config
    location: getDevProjectRegions.outputs.primary
  }
}

module devBoxPools 'devBoxPools.bicep' = {
  name: '${take(deployment().name, 36)}_devBoxPools'
  scope: resourceGroup()
  dependsOn: [
    devProject
  ]
  params: {
    config: config
    networks: resourceRegions.outputs.networks
  }
}
