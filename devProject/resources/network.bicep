import * as tools from '../../shared/tools.bicep'
targetScope = 'resourceGroup'

param config object
param network object
param networkIndex int

var networkHub = contains(network, 'hub') ? network.hub : null
var networkGW = contains(network, 'gateway') ? network.gateway : null

resource routeTable 'Microsoft.Network/routeTables@2022-07-01' = {
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
          addressPrefixes: [ network.addressPrefix ]
          routeTable: {
             id: routeTable.id
          }
        }        
      }
    ]
  }
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: join([network.location, config.name, config.zone], '.')
}

resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: dnsZone.name
  location: 'global'
  parent: dnsZone
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

module registerIpGroup '../../shared/registerIpGroup.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name, virtualNetwork.id)}'
  scope: resourceGroup(split(networkHub.id, '/')[2], split(networkHub.id, '/')[4])
  params: {
    config: config
    hubName: networkHub.name
    hubLocation: networkHub.location
    ipAddresses: virtualNetwork.properties.addressSpace.addressPrefixes
    networkName: virtualNetwork.name
    networkType: 'DevProject'
  }
}

module peerNetworks '../../shared/peerNetworks.bicep' = {
  name: '${take(deployment().name, 36)}-peer-${format('{0:00}', networkIndex)}'
  scope: subscription()
  params: {
    HubPeeringPrefix: 'DevCenter'
    HubNetworkId: networkHub.id
    HubGatewayIP: empty(networkGW) ? null : networkGW.properties.ipConfigurations[0].properties.privateIPAddress
    SpokePeeringPrefix: 'DevProject'
    SpokeNetworkIds: [ virtualNetwork.id ]
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
  scope: resourceGroup(split(config.devCenterId, '/')[2], split(config.devCenterId, '/')[4])
  params: {
    devCenterName: tools.getResourceName(config.devCenterId)
    devProjectName: config.name
    networkConnectionId: networkConnection.id
  }  
}

output network object = union(network, {
  id: virtualNetwork.id
  name: virtualNetwork.name
  location: virtualNetwork.location
  properties: virtualNetwork.properties
})
