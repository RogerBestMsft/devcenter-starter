import * as tools from '../../shared/tools.bicep'
targetScope = 'resourceGroup'

param config object
param windows365PrincipalId string

@secure()
param secrets object = {}

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
  location: config.location
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
  name: '${take(deployment().name, 36)}-gallery'
  scope: resourceGroup()
  dependsOn: [
    devCenter
  ]
  params: {
    config: config
    windows365PrincipalId: windows365PrincipalId
  }
}

module keyVault 'keyVault.bicep' = {
  name: '${take(deployment().name, 36)}-keyVault'
  scope: resourceGroup()
  dependsOn: [
    devCenter
  ]
  params: {
    config: config
    secrets: secrets
  }
}

module catalogs 'catalogs.bicep' = {
  name: '${take(deployment().name, 36)}-catalogs'
  scope: resourceGroup()
  dependsOn: [
    devCenter
  ]
  params: {
    config: config
    secretRefs: keyVault.outputs.secretRefs
  }
}

module devBoxDefinitions 'devBoxDefinitions.bicep' = {
  name: '${take(deployment().name, 36)}-devBoxDefinitions'
  scope: resourceGroup()
  dependsOn: [
    devCenter
  ]
  params: {
    config: config
  }
}

module environmentTypes 'environmentTypes.bicep' = {
  name: '${take(deployment().name, 36)}-environmentTypes'
  scope: resourceGroup()
  dependsOn: [
    devCenter
  ]
  params: {
    config: config
  }
}

module hubs 'hubs.bicep' = {
  name: '${take(deployment().name, 36)}-hubs'
  scope: resourceGroup()
  params: {
    config: config
  }
}

module networks 'networks.bicep' = {
  name: '${take(deployment().name, 36)}-networks'
  scope: resourceGroup()
  dependsOn: [
    devCenter
    hubs
  ]
  params: {
    config: config
  }
}

