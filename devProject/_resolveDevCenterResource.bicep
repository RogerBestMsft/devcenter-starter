// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param devCenterName string

resource devCenter 'Microsoft.DevCenter/devcenters@2023-10-01-preview' existing = {
  name: devCenterName
}

output devCenterId string = devCenter.id
output devCenterName string = devCenter.name
output devCenterLocation string = devCenter.location
output devCenterProperties object = devCenter.properties
