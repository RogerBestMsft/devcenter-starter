// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param network object
param networkIndex int
param regionPolicyId string

var locationMap = loadJsonContent('./data/locations.json')
var networkName = 'HUB-${tools.getLocationDisplayName(locationMap, network.location, true)}-${format('{0:00}', networkIndex)}'

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
          addressPrefix: cidrSubnet(network.addressPrefix, 26, 0)
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: cidrSubnet(network.addressPrefix, 26, 1)
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: cidrSubnet(network.addressPrefix, 26, 2)
        }      
      }
    ]
  }
}

resource firewallPIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: virtualNetwork.name
  location: network.location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2022-07-01' = {
  name: virtualNetwork.name
  location: network.location
  properties: {
    basePolicy: {
      id: regionPolicyId
    }
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' = {
  name: virtualNetwork.name
  location: network.location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet:{
            id: virtualNetwork.properties.subnets[1].id
          }
          publicIPAddress: {
            id: firewallPIP.id
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}
