// import * as tools from '../../shared/tools.bicep'
targetScope = 'resourceGroup'

param config object

@secure()
param secrets object = {}

var keyVaultSecrets = map(items(secrets), item => union(item, { value: string(item.value)}))

resource devCenter 'Microsoft.DevCenter/devcenters@2023-10-01-preview' existing = {
  name: config.name
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
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

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [for item in keyVaultSecrets : {
  name: item.key
  parent: keyVault
  properties: {
    value: item.value
  }
}]

module keyVaultRefs 'keyVaultRefs.bicep' = {
  name: '${take(deployment().name, 36)}_keyVaultRefs'
  scope: resourceGroup()
  params: {
    keyVaultName: keyVault.name
    keyVaultSecretNames: [ for i in range(0, length(keyVaultSecrets)): keyVaultSecret[i].name ]
  }
}

resource roleDefinitionKeyVaultSecretsUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

module roleAssignmentKeyVaultSecretsUser '../../shared/assignRole2KeyVault.bicep' = {
  name: '${take(deployment().name, 36)}-${uniqueString(deployment().name, 'roleAssignmentKeyVaultSecretsUser')}'
  scope: resourceGroup()
  params: {
    resourceName: keyVault.name
    principalIds: [devCenter.identity.principalId]
    roleDefinitionId: roleDefinitionKeyVaultSecretsUser.id
  }
}

output id string = keyVault.id
output name string = keyVault.name
output properties object = keyVault.properties
output secretRefs object = toObject(keyVaultRefs.outputs.keyVaultSecretRefs, entry => entry.key, entry => entry.value)
