import * as tools from '../../shared/tools.bicep'
targetScope = 'subscription'

param config object
param devCenterPrincipalId string 

resource roleDefinitionOwner 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  scope: subscription()
}

resource roleAssignmentOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, roleDefinitionOwner.id, devCenterPrincipalId)
  scope: subscription()
  properties: {
    roleDefinitionId: roleDefinitionOwner.id
    principalId: devCenterPrincipalId
    principalType: 'ServicePrincipal'
  }
}
