
param resourceName string

param roleDefinitionId string
param principalIds array
param principalType string = 'ServicePrincipal'

resource resource 'Microsoft.DevCenter/projects@2023-10-01-preview' existing = {
  name: resourceName
}

resource roleAssignmentContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (item, index) in principalIds: {
  name: guid(resource.id, roleDefinitionId, item)
  scope: resource
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: item
    principalType: principalType
  }
}]
