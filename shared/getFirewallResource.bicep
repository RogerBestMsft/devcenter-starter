// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param firewallName string

resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' existing = {
  name: firewallName
}

output firewallId string = firewall.id
output firewallName string = firewall.name
output firewallLocation string = firewall.location
output firewallProperties object = firewall.properties
