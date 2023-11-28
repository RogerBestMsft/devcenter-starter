import * as tools from '../../shared/tools.bicep'
targetScope = 'resourceGroup'

param config object
param network object
param networkIndex int

var networkHub = contains(network, 'hub') ? network.hub : {}

resource hubFirewall 'Microsoft.Network/azureFirewalls@2023-05-01' existing = {
  name: networkHub.name
}

resource routeTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: network.name
  location: network.location
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: network.name
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

module registerIpGroup '../../shared/registerIpGroup.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name, virtualNetwork.id)}'
  scope: resourceGroup()
  params: {
    config: config
    hubLocation: networkHub.location
    hubName: networkHub.name
    ipAddresses: virtualNetwork.properties.addressSpace.addressPrefixes
    networkName: virtualNetwork.name
    networkType: 'DevCenter'
  }
}

module peerNetworks '../../shared/peerNetworks.bicep' = {
  name: '${take(deployment().name, 36)}-peer-${network.location}-${format('{0:00}', networkIndex)}'
  scope: subscription()
  params: {
    HubNetworkId: networkHub.id
    HubGatewayIP: hubFirewall.properties.ipConfigurations[0].properties.privateIPAddress
    HubPeeringPrefix: 'DevCenterNet'
    SpokeNetworkIds: [ virtualNetwork.id ]
    SpokePeeringPrefix: 'DevCenterHub'
  }
}

resource networkConnection 'Microsoft.DevCenter/networkConnections@2023-10-01-preview' = {
  name: network.name
  location: network.location
  dependsOn: [
    peerNetworks    
  ]
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: virtualNetwork.properties.subnets[0].id
    networkingResourceGroupName: '${resourceGroup().name}-NI-${uniqueString(virtualNetwork.properties.subnets[0].id)}'
  }
}

module attachNetworkConnection '../../shared/attachNetworkConnection.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name, networkConnection.id)}'
  scope: resourceGroup()
  params: {
    devCenterName: config.name
    networkConnectionId: networkConnection.id
  }  
}


