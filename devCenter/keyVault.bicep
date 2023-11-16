// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param devCenterName string
param devCenterPrincipalId string

resource devCenter 'Microsoft.DevCenter/devcenters@2023-10-01-preview' existing = {
  name: devCenterName
}

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: devCenter.name
  location: config.location
  properties: {
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
    createMode: 'default'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
  }
}

resource roleDefinitionKeyVaultSecretsUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

resource roleAssignmentKeyVaultSecretsUser 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(vault.id, roleDefinitionKeyVaultSecretsUser.id, devCenterPrincipalId)
  scope: vault
  properties: {
    roleDefinitionId: roleDefinitionKeyVaultSecretsUser.id
    principalId: devCenterPrincipalId
    principalType: 'ServicePrincipal'
  }
}
