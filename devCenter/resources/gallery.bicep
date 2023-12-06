// import * as tools from '../../shared/tools.bicep'
targetScope = 'resourceGroup'

param config object
param windows365PrincipalId string

var galleryName = replace(config.name, '-', '_')

resource devCenter 'Microsoft.DevCenter/devcenters@2023-10-01-preview' existing = {
  name: config.name
}

resource gallery 'Microsoft.Compute/galleries@2021-10-01' = {
  name: galleryName
  location: config.location
}

resource roleDefinitionContributor 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  scope: subscription()
}

module roleAssignmentContributor '../../shared/assignRole2Gallery.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name, 'roleAssignmentContributor')}'
  scope: resourceGroup()
  params: {
    resourceName: gallery.name
    principalIds: [devCenter.identity.principalId]
    roleDefinitionId: roleDefinitionContributor.id
  }
}

resource roleDefinitionReader 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  scope: subscription()
}

module roleAssignmentReader '../../shared/assignRole2Gallery.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name, 'roleAssignmentReader')}'
  scope: resourceGroup()
  params: {
    resourceName: gallery.name
    principalIds: [windows365PrincipalId]
    roleDefinitionId: roleDefinitionReader.id
  }
}

resource attachGallery 'Microsoft.DevCenter/devcenters/galleries@2023-10-01-preview' = {
  name: gallery.name
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
