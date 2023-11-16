// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param location string

var adminPrincipals = contains(config, 'admins') ? config.admins : []
var userPrincipals = contains(config, 'users') ? config.users : []

resource devProject 'Microsoft.DevCenter/projects@2022-11-11-preview' = {
  name: config.name
  location: location
  properties: {
    devCenterId: config.devCenterId
  }
}

resource roleDefinitionDevCenterProjectAdmin 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: '331c37c6-af14-46d9-b9f4-e1909e1b95a0'
  scope: subscription()
}

resource roleAssignmentDevCenterProjectAdmin 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = [for adminPrincipal in adminPrincipals: {
  name: guid(devProject.id, roleDefinitionDevCenterProjectAdmin.id, adminPrincipal.principalId)
  scope: devProject
  properties: {
    roleDefinitionId: roleDefinitionDevCenterProjectAdmin.id
    principalId: adminPrincipal.principalId
    principalType: contains(adminPrincipal, 'principalType') ? adminPrincipal.principalType : 'User'
  }
}]

resource roleDefinitionDevCenterDevBoxUser 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: '45d50f46-0b78-4001-a660-4198cbe8cd05'
  scope: subscription()
}

resource roleAssignmentDevCenterDevBoxUser 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = [for userPrincipal in userPrincipals: {
  name: guid(devProject.id, roleDefinitionDevCenterDevBoxUser.id, userPrincipal.principalId)
  scope: devProject
  properties: {
    roleDefinitionId: roleDefinitionDevCenterDevBoxUser.id
    principalId: userPrincipal.principalId
    principalType: contains(userPrincipal, 'principalType') ? userPrincipal.principalType : 'User'
  }
}]

resource roleDefinitionDevCenterEnvironmentUser 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: '18e40d4e-8d2e-438d-97e1-9528336e149c'
  scope: subscription()
}

resource roleAssignmentDevCenterEnvironmentUser 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = [for userPrincipal in userPrincipals: {
  name: guid(devProject.id, roleDefinitionDevCenterEnvironmentUser.id, userPrincipal.principalId)
  scope: devProject
  properties: {
    roleDefinitionId: roleDefinitionDevCenterEnvironmentUser.id
    principalId: userPrincipal.principalId
    principalType: contains(userPrincipal, 'principalType') ? userPrincipal.principalType : 'User'
  }
}]
