// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param zone string
param linkNetworkIds array = []
param autoNetworkIds array = []

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: zone
}

resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (item, index) in union(linkNetworkIds, autoNetworkIds): if (!empty(item)) {
  name: 'Link-${guid(item)}'
  location: 'global'
  parent: dnsZone
  properties: {
    registrationEnabled: contains(autoNetworkIds, item)
    virtualNetwork: {
      id: item
    }
  }
}]
