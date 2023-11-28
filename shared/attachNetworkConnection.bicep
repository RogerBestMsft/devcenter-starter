import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param devCenterName string
param devProjectName string = ''
param networkConnectionId string

var attachmentName = empty(devProjectName)
  ? tools.getDCNetworkAttachmentName(devCenterName, networkConnectionId)
  : tools.getDPNetworkAttachmentName(devProjectName, networkConnectionId)

resource devCenter 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devCenterName
}

resource attachNetworkConnection 'Microsoft.DevCenter/devcenters/attachednetworks@2022-11-11-preview' = {
  name: attachmentName
  parent: devCenter
  properties: {
    networkConnectionId: networkConnectionId
  }
}
