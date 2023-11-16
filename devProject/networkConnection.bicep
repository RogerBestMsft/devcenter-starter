// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param networkName string
param networkLocation string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: networkName
}

resource networkConnection 'Microsoft.DevCenter/networkConnections@2023-10-01-preview' = {
  name: networkName
  location: networkLocation
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: virtualNetwork.properties.subnets[0].id
    networkingResourceGroupName: 'DevProject-${config.name}-NI-${uniqueString(virtualNetwork.properties.subnets[0].id)}'
  }
}

module networkConnectionAttach 'networkConnectionAttach.bicep' = {
  name: '${take(deployment().name, 36)}_atnc_${uniqueString(networkConnection.id)}'
  scope: resourceGroup(split(config.devCenterId, '/')[2], split(config.devCenterId, '/')[4])
  params: {
    DevCenterName: last(split(config.devCenterId, '/'))
    NetworkConnectionId: networkConnection.id
  }  
}
