import * as tools from '../../shared/tools.bicep'
targetScope = 'resourceGroup'

param config object
param hub object
param hubIndex int
param policyId string

var locationsMap = loadJsonContent('../data/locations.json')

resource routes 'Microsoft.Network/routeTables@2023-05-01' = {
  name: hub.name
  location: hub.location
  properties: {
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: hub.name
  location: hub.location
  properties: {
    addressSpace: {
      addressPrefixes: [ hub.addressPrefix ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: cidrSubnet(hub.addressPrefix, 26, 0)
          routeTable: {
            id: routes.id
          }
        }
      }
      {
        name: 'AzureFirewallManagementSubnet'
        properties: {
          addressPrefix: cidrSubnet(hub.addressPrefix, 26, 1)
        }
      }
    ]
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2022-07-01' = {
  name: virtualNetwork.name
  location: hub.location
  properties: {
    basePolicy: {
      id: policyId
    }
  }
}

resource firewallPIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: virtualNetwork.name
  location: hub.location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {    
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource firewallPIPMgmt 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${virtualNetwork.name}-Mgmt'
  location: hub.location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {    
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' = {
  name: virtualNetwork.name
  location: hub.location
  properties: {
    sku: {
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: firewallPIP.name        
        properties: {
          publicIPAddress: {
            id: firewallPIP.id
          }
          subnet:{
            id: virtualNetwork.properties.subnets[0].id
          }
        }
      }
    ]
    managementIpConfiguration: {
      name: firewallPIPMgmt.name
      properties: {
        publicIPAddress: {
          id: firewallPIPMgmt.id
        }
        subnet: {
          id: virtualNetwork.properties.subnets[1].id
        }
      }
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }    
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: config.name
}

resource firewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: firewall.name
  scope: firewall
  properties: {
    workspaceId: workspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

