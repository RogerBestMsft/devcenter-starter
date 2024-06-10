import * as tools from '../shared/tools.bicep'
targetScope = 'subscription'

param config object
param resolve bool = false

//@secure()
//param secrets object

module mainResolve 'mainResolve.bicep' = {
  name: '${take(deployment().name, 36)}-mainResolve'
  scope: subscription()
  params: {
    config: config    
  }  
}

module mainProvision 'mainProvision.bicep' = if (!resolve) {
  name: '${take(deployment().name, 36)}-mainProvision'
  scope: subscription()
  params: {
    config: mainResolve.outputs.config
//    secrets: secrets
  }
}

output config object = mainResolve.outputs.config
