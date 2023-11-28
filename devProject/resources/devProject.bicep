// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object

var adminPrincipals = contains(config, 'admins') ? config.admins : []
var userPrincipals = contains(config, 'users') ? config.users : []

resource devProject 'Microsoft.DevCenter/projects@2022-11-11-preview' = {
  name: config.name
  location: config.location
  properties: {
    devCenterId: config.devCenterId
  }
}

resource roleDefinitionDevCenterProjectAdmin 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: '331c37c6-af14-46d9-b9f4-e1909e1b95a0'
  scope: subscription()
}

module roleAssignmentDevCenterProjectAdmin '../../shared/assignRole2DevProject.bicep' = [for (item, index) in adminPrincipals: {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name, 'roleAssignmentDevCenterProjectAdmin', string(item))}'
  scope: resourceGroup()
  params: {
    resourceName: devProject.name
    principalIds: [item.principalId]
    principalType: contains(item, 'principalType') ? item.principalType : 'User'
    roleDefinitionId: roleDefinitionDevCenterProjectAdmin.id
  }
}]

resource roleDefinitionDevCenterDevBoxUser 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: '45d50f46-0b78-4001-a660-4198cbe8cd05'
  scope: subscription()
}

module roleAssignmentDevCenterDevBoxUser '../../shared/assignRole2DevProject.bicep' = [for (item, index) in userPrincipals: {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name, 'roleAssignmentDevCenterDevBoxUser', string(item))}'
  scope: resourceGroup()
  params: {
    resourceName: devProject.name
    principalIds: [item.principalId]
    principalType: contains(item, 'principalType') ? item.principalType : 'User'
    roleDefinitionId: roleDefinitionDevCenterDevBoxUser.id
  }
}]

resource roleDefinitionDevCenterEnvironmentUser 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: '18e40d4e-8d2e-438d-97e1-9528336e149c'
  scope: subscription()
}

module roleAssignmentDevCenterEnvironmentUser '../../shared/assignRole2DevProject.bicep' = [for (item, index) in userPrincipals: {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name, 'roleAssignmentDevCenterEnvironmentUser', string(item))}'
  scope: resourceGroup()
  params: {
    resourceName: devProject.name
    principalIds: [item.principalId]
    principalType: contains(item, 'principalType') ? item.principalType : 'User'
    roleDefinitionId: roleDefinitionDevCenterEnvironmentUser.id
  }
}]

output devProjectId string = devProject.id
output devProjectName string = devProject.name
output devProjectLocation string = devProject.location
output devProjectProperties object = devProject.properties
