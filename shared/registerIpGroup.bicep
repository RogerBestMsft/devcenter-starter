// import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param hubName string
param hubLocation string
param networkName string
@allowed(['DevCenter', 'DevProject'])
param networkType string
param ipAddresses array

var networkTypeCharacters = map(range(0, length(networkType)), i => substring(networkType, i, 1))
var networkTypeIdentifier = reduce(networkTypeCharacters, '', (cur, next) => toUpper(next) == next ? '${cur}${next}' : cur)

resource ipGroup 'Microsoft.Network/ipGroups@2022-01-01' ={
  name: '${hubName}-${networkTypeIdentifier}IPG-${config.name}-${networkName}'
  location: hubLocation
  properties: {
    ipAddresses: ipAddresses 
  }
}

