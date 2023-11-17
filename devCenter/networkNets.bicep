import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param network object
param networkIndex int
param networkHubs array

var locationMap = loadJsonContent('./data/locations.json')
var networkName = 'NET-${tools.getLocationDisplayName(locationMap, network.location, true)}-${format('{0:00}', networkIndex)}'
var networkHub = networkHubs[(networkIndex < length(networkHubs)) ? networkIndex : (networkIndex % length(networkHubs))]

resource devCenter 'Microsoft.DevCenter/devcenters@2023-10-01-preview' existing = {
  name: config.name
}

resource hubFirewall 'Microsoft.Network/azureFirewalls@2023-05-01' existing = {
  name: networkHub.name
}

resource routeTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: networkName
  location: network.location
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: networkName
  location: network.location
  properties: {
    addressSpace: {
      addressPrefixes: [ network.addressPrefix ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: network.addressPrefix
          routeTable: {
            id: routeTable.id
          }
        }
      }
    ]
  }
}

module networkPeerings 'networkPeerings.bicep' = {
  name: '${take(deployment().name, 36)}-peer-${network.location}-${format('{0:00}', networkIndex)}'
  scope: subscription()
  params: {
    HubNetworkId: networkHub.id
    HubGatewayIP: hubFirewall.properties.ipConfigurations[0].properties.privateIPAddress
    SpokeNetworkIds: [ virtualNetwork.id ]
  }
}

resource networkConnection 'Microsoft.DevCenter/networkConnections@2023-10-01-preview' = {
  name: networkName
  location: network.location
  dependsOn: [
    networkPeerings    
  ]
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: virtualNetwork.properties.subnets[0].id
    networkingResourceGroupName: 'DevCenter-${config.name}-NI-${uniqueString(virtualNetwork.properties.subnets[0].id)}'
  }
}

resource networkConnectionAttach 'Microsoft.DevCenter/devcenters/attachednetworks@2022-11-11-preview' = {
  name: networkName
  parent: devCenter
  properties: {
    networkConnectionId: networkConnection.id
  }
}

resource ipGroup 'Microsoft.Network/ipGroups@2022-01-01' = {
  name: '${networkHub.name}-DCIPG-${config.name}-${networkName}'
  location: networkHub.location
  properties: {
    ipAddresses: virtualNetwork.properties.addressSpace.addressPrefixes
  }
}

output network object = union(network, {
  id: virtualNetwork.id
  name: virtualNetwork.name
  properties: virtualNetwork.properties
})
