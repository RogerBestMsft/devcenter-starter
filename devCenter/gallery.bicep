// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param devCenterName string
param devCenterPrincipalId string
param windows365PrincipalId string

resource devCenter 'Microsoft.DevCenter/devcenters@2023-10-01-preview' existing = {
  name: devCenterName
}

resource gallery 'Microsoft.Compute/galleries@2021-10-01' = {
  name: config.name
  location: config.location
}

resource roleDefinitionContributor 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  scope: subscription()
}

resource roleAssignmentContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(gallery.id, roleDefinitionContributor.id, devCenterPrincipalId)
  scope: gallery
  properties: {
    roleDefinitionId: roleDefinitionContributor.id
    principalId: devCenterPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource roleDefinitionReader 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  scope: subscription()
}

resource roleAssignmentReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(gallery.id, roleDefinitionReader.id, windows365PrincipalId)
  scope: gallery
  properties: {
    roleDefinitionId: roleDefinitionReader.id
    principalId: devCenterPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource attachGallery 'Microsoft.DevCenter/devcenters/galleries@2023-10-01-preview' = {
  name: config.name
  parent: devCenter
  dependsOn: [
    roleAssignmentContributor
    roleAssignmentReader
  ]
  properties: {
    #disable-next-line use-resource-id-functions
    galleryResourceId: gallery.id
  }
}

output galleryId string = gallery.id
output galleryName string = gallery.name
output galleryProperties object = gallery.properties
