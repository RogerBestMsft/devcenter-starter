import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param network object
param networkIndex int

var locationMap = loadJsonContent('data/locations.json')
var networkName = '${config.name}-NET-${tools.getLocationDisplayName(locationMap, network.location, true)}-${format('{0:00}', networkIndex)}'

module resolveNetworkResource '_resolveNetworkResource.bicep' = if (contains(network, 'hubId')) {
  name: '${take(deployment().name, 36)}_vninfo_${uniqueString(deployment().name)}'
  scope: resourceGroup(split(network.hubId, '/')[2], split(network.hubId, '/')[4])
  params: {
    networkName: last(split(network.hubId, '/'))
  }
}

module resolveFirewallResource '_resolveFirewallResource.bicep' = if (contains(network, 'hubId')) {
  name: '${take(deployment().name, 36)}_fwinfo_${uniqueString(deployment().name)}'
  scope: resourceGroup(split(network.hubId, '/')[2], split(network.hubId, '/')[4])
  params: {
    firewallName: last(split(network.hubId, '/'))
  }
}

resource routeTable 'Microsoft.Network/routeTables@2022-07-01' = {
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
          addressPrefixes: [ network.addressPrefix ]
          routeTable: {
             id: routeTable.id
          }
        }        
      }
    ]
  }
}

module networkIpGroup 'networkIpGroup.bicep' = if (contains(network, 'hubId')) {
  name: '${take(deployment().name, 36)}-net-${network.location}${format('{0:00}', networkIndex)}'
  scope: resourceGroup(split(network.hubId, '/')[2], split(network.hubId, '/')[4])
  params: {
    name: '${last(split(network.hubId, '/'))}-IPG-${networkName}'
    location: resolveNetworkResource.outputs.networkLocation
    addresses: [ network.addressPrefix ]
  }
}

module networkPeerings 'networkPeerings.bicep' = if (contains(network, 'hubId')) {
  name: '${take(deployment().name, 36)}-peer-${network.location}${format('{0:00}', networkIndex)}'
  scope: subscription()
  params: {
    HubPeeringPrefix: 'devCenter'
    HubNetworkId: network.hubId
    HubGatewayIP: resolveFirewallResource.outputs.firewallProperties.ipConfigurations[0].properties.privateIPAddress
    SpokePeeringPrefix: 'devProject'
    SpokeNetworkIds: [ virtualNetwork.id ]
  }
}

module networkConnection 'networkConnection.bicep' = {
  name: '${take(deployment().name, 36)}-con-${network.location}${format('{0:00}', networkIndex)}'
  dependsOn: [
    networkPeerings
  ]
  params: {
    config: config
    networkName: networkName
    networkLocation: network.location
  }
}

output network object = union(network, {
  id: virtualNetwork.id
  name: virtualNetwork.name
  location: virtualNetwork.location
  properties: virtualNetwork.properties
})
