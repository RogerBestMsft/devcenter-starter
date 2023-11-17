// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param devCenterName string

var devBoxDefinitions = contains(config, 'devBoxDefinitions') ? config.devBoxDefinitions : []

resource devCenter 'Microsoft.DevCenter/devcenters@2023-10-01-preview' existing = {
  name: devCenterName
}

resource devBox 'Microsoft.DevCenter/devcenters/devboxdefinitions@2023-10-01-preview' = [for devBoxDefinition in devBoxDefinitions: {
  name: devBoxDefinition.name
  location: toLower(replace(config.location, ' ', ''))
  parent: devCenter
  properties: {
    imageReference: {
      id: resourceId('Microsoft.DevCenter/devcenters/galleries/images', devCenter.name, 'default', devBoxDefinition.image)
    }
    sku: {
      name: devBoxDefinition.sku
    }
    osStorageType: devBoxDefinition.storage
    hibernateSupport: 'Enabled'
  }
}]
