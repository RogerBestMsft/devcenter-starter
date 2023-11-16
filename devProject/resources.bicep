// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object

module resolveDevProjectRegions '_resolveDevProjectRegions.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString('resolveDevProjectRegions', string(config))}'
  scope: subscription()
  params: {
    config: config
  }
}

module resolveDevProjectNetworks '_resolveDevProjectNetworks.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString('resolveDevProjectNetworks', string(config))}'
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
    locations: resolveDevProjectRegions.outputs.regions
    networks: resolveDevProjectNetworks.outputs.networks
  }
}

module devProject 'devProject.bicep' = {
  name: '${take(deployment().name, 36)}-devProject'
  scope: resourceGroup()
  params: {
    config: config
    location: resolveDevProjectRegions.outputs.primary
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
