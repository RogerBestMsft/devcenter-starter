// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param networkName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: networkName
}

output networkId string = virtualNetwork.id
output networkName string = virtualNetwork.name
output networkLocation string = virtualNetwork.location
output networkProperties object = virtualNetwork.properties
