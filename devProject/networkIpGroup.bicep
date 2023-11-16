// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param name string 
param location string
param addresses array

resource ipGroup 'Microsoft.Network/ipGroups@2022-01-01' = {
  name: name
  location: location
  properties: {
    ipAddresses: addresses
  }
}
