// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param devCenterName string

@secure()
param secretRefs object

var catalogs = map(contains(config, 'catalogs') ? config.catalogs : [], cat => union(cat, {
  branch: (contains(cat, 'branch') ? cat.branch : 'main')
  path: (contains(cat, 'path') ? cat.path : '/')
}))

var catalogsGitHub = filter(catalogs, item => item.type == 'GitHub')
var catalogsAzureDevOps = filter(catalogs, item => item.type == 'AzureDevOps')

resource devCenter 'Microsoft.DevCenter/devcenters@2023-10-01-preview' existing = {
  name: devCenterName
}

resource catalogGitHub 'Microsoft.DevCenter/devcenters/catalogs@2023-10-01-preview' = [for item in catalogsGitHub : {
  name: item.name
  parent: devCenter
  properties: {
    gitHub: {
      uri: item.uri
      branch: item.branch
      secretIdentifier: filter(items(secretRefs), sec => sec.key == item.secretRef)[0].value
      path: item.path
    }    
    syncType: 'Scheduled'
  }
}]

resource catalogAzureDevOps 'Microsoft.DevCenter/devcenters/catalogs@2023-10-01-preview' = [for item in catalogsAzureDevOps : {
  name: item.name
  parent: devCenter
  properties: {
    adoGit: {
      uri: item.uri
      branch: item.branch
      secretIdentifier: filter(items(secretRefs), sec => sec.key == item.key)[0].value
      path: item.path
    }
    syncType: 'Scheduled'
  }
}]
