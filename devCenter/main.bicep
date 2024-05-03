// import * as tools from '../shared/tools.bicep'
targetScope = 'subscription'

param config object
param resolve bool = false
param windows365PrincipalId string

@secure()
param secrets string

var  secrets2 = json(secrets)

// module mainResolve 'mainResolve.bicep' = {
//   name: '${take(deployment().name, 36)}-resolve'
//   scope: subscription()
//   params: {
//     config: config
//   }
// }

// module mainProvision 'mainProvision.bicep' = if(!resolve) {
//   name: '${take(deployment().name, 36)}-provision'
//   scope: subscription()
//   params: {
//     config: mainResolve.outputs.config    
//     secrets: secrets2
//     windows365PrincipalId: windows365PrincipalId
//   }
// }

// output config object = mainResolve.outputs.config

output test object = secrets2
