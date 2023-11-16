// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param networks array

var pools = map(contains(config, 'devBoxPools') ? config.devBoxPools : [], pool => union(pool, {
  networks: map((contains(pool, 'networks') ? pool.networks : [0]), networkIndex => networks[networkIndex])
}))

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' existing = {
  name: config.name
}

module devBoxPool 'devBoxPool.bicep' = [for pool in pools: {
  name: '${take(deployment().name, 36)}-devBoxPool-${uniqueString(string(pool))}'
  scope: resourceGroup()
  params: {
    config: config    
    pool: union(pool, { location: project.location })
  }
}]
