// import * as tools from 'tools.bicep'
targetScope = 'subscription'

param config object
param windows365PrincipalId string

@secure()
param secrets object = {}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'DevCenter-${config.name}'
  location: config.location
}

module resources 'resources.bicep' = {
  name: '${take(deployment().name, 36)}-resources'
  scope: resourceGroup
  params: {
    config: config
    windows365PrincipalId: windows365PrincipalId
    secrets: secrets
  }
}

output workspaceId string = resources.outputs.workspaceId
output devCenterId string = resources.outputs.devCenterId
