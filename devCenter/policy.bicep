// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param location string = config.location

var devCenterRuleCollections = [
  {
    name: 'DevCenter-NetworkRules'
    priority: 1000
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    action: {
      type: 'Allow'
    }
    rules: [
      {
        ruleType: 'NetworkRule'
        name: 'avd-common'
        ipProtocols: [ 'TCP' ]
        sourceAddresses: [ '*' ]
        destinationFqdns: [
          'oneocsp.microsoft.com'
          'www.microsoft.com'
        ]
        destinationPorts: [ '80' ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'avd-storage'
        ipProtocols: [ 'TCP' ]
        sourceAddresses: [ '*' ]
        destinationFqdns: [
          'mrsglobalsteus2prod.blob.${environment().suffixes.storage}'
          'wvdportalstorageblob.blob.${environment().suffixes.storage}'
        ]
        destinationPorts: [ '443' ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'avd-services'
        ipProtocols: [ 'TCP' ]
        sourceAddresses: [ '*' ]
        destinationAddresses: [
          'WindowsVirtualDesktop'
          'AzureFrontDoor.Frontend'
          'AzureMonitor'
        ]
        destinationPorts: [ '443' ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'avd-kms'
        ipProtocols: [ 'TCP' ]
        sourceAddresses: [ '*' ]
        destinationFqdns: [
          'azkms.${environment().suffixes.storage}'
          'kms.${environment().suffixes.storage}'
        ]
        destinationPorts: [ '1688' ]
      }      
      {
        ruleType: 'NetworkRule'
        name: 'avd-devices'
        ipProtocols: [ 'TCP' ]
        sourceAddresses: [ '*' ]
        destinationFqdns: [
          'global.azure-devices-provisioning.net'
        ]
        destinationPorts: [ '5671' ]
      }   
      {
        ruleType: 'NetworkRule'
        name: 'avd-fastpath-ip'
        ipProtocols: [ 'UDP' ]
        sourceAddresses: [ '*' ]
        destinationAddresses: [ '13.107.17.41' ]
        destinationPorts: [ '3478' ]
      }  
      {
        ruleType: 'NetworkRule'
        name: 'avd-fastpath-fqdn'
        ipProtocols: [ 'UDP' ]
        sourceAddresses: [ '*' ]
        destinationFqdns: [ 'stun.azure.com' ]
        destinationPorts: [ '3478' ]
      }  
      {
        ruleType: 'NetworkRule'
        name: 'time-windows-address'
        ipProtocols: [ 'UDP' ]
        sourceAddresses: [ '*' ]
        destinationAddresses: [ '13.86.101.172' ]
        destinationPorts: [ '123' ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'time-windows-fqdn'
        ipProtocols: [ 'UDP' ]
        sourceAddresses: [ '*' ]
        destinationFqdns: [ 'time.windows.com' ]
        destinationPorts: [ '123' ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'microsoft-login'
        ipProtocols: [ 'TCP' ]
        sourceAddresses: [ '*' ]
        destinationFqdns: [ 
          split(environment().authentication.loginEndpoint, '/')[2] 
          'login.windows.net'
        ]
        destinationPorts: [ '443' ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'microsoft-connect'
        ipProtocols: [ 'TCP' ]
        sourceAddresses: [ '*' ]
        destinationFqdns: [ 'www.msftconnecttest.com' ]
        destinationPorts: [ '443' ]
      }
    ]
  }
  {
    name: 'DevCenter-ApplicationRules'
    priority: 2000
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    action: {
      type: 'Allow'
    }
    rules: [
      {
        ruleType: 'ApplicationRule'
        name: 'WindowsUpdate'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        fqdnTags: [
          'WindowsUpdate'
        ]
        sourceAddresses: [ '*' ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'WindowsVirtualDesktop'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
        ]
        fqdnTags: [
          'WindowsVirtualDesktop'
          'WindowsDiagnostics'
          'MicrosoftActiveProtectionService'
        ]
        destinationAddresses: [
          '*.events.data.microsoft.com'
          '*.sfx.ms'
          '*.digicert.com'
          '*.azure-dns.com'
          '*.azure-dns.net'
        ]
        sourceAddresses: [ '*' ]
      }
    ]
  }

]

var browserRuleCollections = [
  {
    name: 'WebCategories'
    priority: 2100
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    action: {
      type: 'Allow'
    }
    rules: [
      {
        ruleType: 'ApplicationRule'
        name: 'general'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        webCategories: [
          'ComputersAndTechnology'
          'InformationSecurity'
          'WebRepositoryAndStorage'
          'SearchEnginesAndPortals'
        ]
        terminateTLS: false
        sourceAddresses: [ '*' ]
      }
    ]
  }
]

var ruleCollectionGroups = [
  {
    name: 'DevCenter'
    ruleCollections: devCenterRuleCollections
  }
  {
    name: 'Browser'
    ruleCollections: browserRuleCollections
  }
]

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2022-07-01' = {
  name: 'POLICY-${toUpper(replace(location, ' ', ''))}'
  location: location
  properties: {
    threatIntelMode: 'Alert'
    dnsSettings: {
      enableProxy: true
      servers: [
        '168.63.129.16'
      ]
    }
  }
}

@batchSize(1)
resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-05-01' = [for (group, index) in ruleCollectionGroups:{
  name: group.name
  parent: firewallPolicy
  properties: {
    priority: (index + 1) * 100
    ruleCollections: group.ruleCollections
  }
}]

output firewallPolicyId string = firewallPolicy.id
