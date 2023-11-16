// import * as tools from 'tools.bicep'
targetScope = 'subscription'

param config object
param location string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'DevProject-${config.name}'
  location: location
}

module resources 'resources.bicep' = {
  name: '${take(deployment().name, 36)}-resources'
  scope: resourceGroup
  params: {
    config: config
  }
}

