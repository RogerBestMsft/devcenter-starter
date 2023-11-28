// import * as tools from '../../shared/tools.bicep'
targetScope = 'resourceGroup'

param keyVaultName string
param keyVaultSecretNames array = []

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' existing = [for item in keyVaultSecretNames: {
  name: item
  parent: keyVault
}]

output keyVaultSecretRefs array = [for i in range(0, length(keyVaultSecretNames)): { key: keyVaultSecret[i].name, value: keyVaultSecret[i].properties.secretUri }]
