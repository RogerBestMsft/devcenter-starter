import * as tools from 'tools.bicep'
targetScope = 'resourceGroup'

param config object
param environmentType object
param settingsStoreId string
param settingsVaultId string

var rolesMap = loadJsonContent('data/roles.json')

var creatorRoleIds = union(map((contains(environmentType, 'creatorRoles') ? environmentType.creatorRoles : [ 'Reader' ]), roleName => tools.getRoleId(rolesMap, roleName)), [])
var creatorRoleAssignment = { roles: toObject(creatorRoleIds, item => item, item => {}) }

var userRoleIds = union(map((contains(environmentType, 'userRoles') ? environmentType.userRoles : [ 'Reader' ]), roleName => tools.getRoleId(rolesMap, roleName)), [])
var userRoleAssignments = map(tools.distinct(map((contains(config, 'users') ? config.users : []), usr => usr.principalId)), usr => { '${usr}': { roles: toObject(userRoleIds, item => item, item => {}) } })

resource devProject 'Microsoft.DevCenter/projects@2023-10-01-preview' existing = {
  name: config.name
}

resource environment 'Microsoft.DevCenter/projects/environmentTypes@2023-10-01-preview' = {
  name: environmentType.name
  parent: devProject
  identity: {
    type: 'SystemAssigned'
  }
  tags: union(contains(environmentType, 'tags')? environmentType.tags : {}, {
    'hidden-ConfigurationLabel': environmentType.name
    'hidden-ConfigurationStoreId': settingsStoreId
    'hidden-ConfigurationVaultId': settingsVaultId
  })
  properties: {
    deploymentTargetId: '/subscriptions/${environmentType.subscription}'
    status: 'Enabled'
    creatorRoleAssignment: creatorRoleAssignment
    userRoleAssignments: empty(userRoleAssignments) ? null : reduce(userRoleAssignments, {}, (cur, next) => union(cur, next))
  }
}
