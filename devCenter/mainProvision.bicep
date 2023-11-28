// import * as tools from '../shared/tools.bicep'
targetScope = 'subscription'

param config object
param windows365PrincipalId string

@secure()
param secrets object = {}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: config.resourceGroup
  location: config.location
}

module resources 'resources/resources.bicep' = {
  name: '${take(deployment().name, 36)}-resources'
  scope: resourceGroup
  params: {
    config: config
    windows365PrincipalId: windows365PrincipalId
    secrets: secrets
  }
}
