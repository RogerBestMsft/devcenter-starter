// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param windows365PrincipalId string

var locations = union(
  [replace(toLower(config.location), ' ', '')],
  map((contains(config, 'networks') ? config.networks : []), network => toLower(replace(contains(network, 'location') ? network.location : config.location, ' ', ''))))

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: config.name
  location: config.location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
}

resource devCenter 'Microsoft.DevCenter/devcenters@2023-10-01-preview' = {
  name: config.name
  location: toLower(replace(config.location, ' ', ''))
  identity: {
    type: 'SystemAssigned'
  }
}

resource devCenterDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: devCenter.name
  scope: devCenter
  properties: {
    workspaceId: workspace.id
    logs: [
      {
        categoryGroup: 'audit'
        enabled: true
      }
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

module gallery 'gallery.bicep' = {
  name: '${take(deployment().name, 36)}_gallery'
  scope: resourceGroup()
  params: {
    config: config
    devCenterName: devCenter.name
    devCenterPrincipalId: devCenter.identity.principalId
    windows365PrincipalId: windows365PrincipalId
  }
}

module region 'resourceRegion.bicep' = [for location in locations: {
  name: '${take(deployment().name, 36)}_region_${location}'
  scope: resourceGroup()
  params: {
    config: config
    location: location
  }
}]

module devBox 'devBox.bicep' = {
  name: '${take(deployment().name, 36)}_devBox'
  scope: resourceGroup()
  params: {
    config: config
    devCenterName: devCenter.name
  }
}

module keyVault 'keyVault.bicep' = {
  name: '${take(deployment().name, 36)}_keyVault'
  scope: resourceGroup()
  params: {
    config: config
    devCenterName: devCenter.name
    devCenterPrincipalId: devCenter.identity.principalId
  }
}

output workspaceId string = workspace.id
output devCenterId string = devCenter.id
