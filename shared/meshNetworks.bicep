import * as tools from 'tools.bicep'
targetScope = 'subscription'

param meshNetworkIds array
param meshPeeringPrefix string = 'Mesh'
param OperationId string = guid(deployment().name)

module peerNetworks 'peerNetworks.bicep' = [for (item, index) in meshNetworkIds: if ((index + 1) < length(meshNetworkIds)) {
  name: '${take(deployment().name, 36)}_${uniqueString('mesh', item, OperationId)}'
  scope: subscription(split(item, '/')[2])
  params: {
    HubNetworkId: item
    HubPeeringPrefix: meshPeeringPrefix
    SpokeNetworkIds: skip(meshNetworkIds, (index + 1))
    SpokePeeringPrefix: meshPeeringPrefix
  }
}]
