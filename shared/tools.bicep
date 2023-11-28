@export()
func generalizeLocation(location string) string => 
  toLower(replace(location, ' ', ''))

@export()
func getLocationDisplayName(locationMap object, location string, removeBlanks bool) string => 
  contains(locationMap, generalizeLocation(location)) ? replace(filter(items(locationMap), item => item.key == generalizeLocation(location))[0].value, (removeBlanks ? ' ' : '') , '') : replace(location, (removeBlanks ? ' ' : '') , '')

@export()
func generalizeRoleName(roleName string) string =>
  toLower(replace(roleName, ' ', ''))

@export()
func getRoleId(roleMap object, roleName string) string =>
  contains(roleMap, generalizeRoleName(roleName)) ? filter(items(roleMap), item => item.key == generalizeLocation(roleName))[0].value : roleName

@export()
func getSubscriptionId(resourceId string) string => 
  split(resourceId, '/')[2]

@export()
func getResourceGroupName(resourceId string) string => 
  split(resourceId, '/')[4]

@export()
func getResourceName(resourceId string) string => 
  last(split(resourceId, '/'))

@export()
func distinct(values array) array => 
  union(values, [])

@export()
func getRegionalFirewallPolicyName(locationMap object, location string) string =>
  'POLICY-${getLocationDisplayName(locationMap, location, true)}}'
  
@export()
func getDCNETNetworkName(name string, locationMap object, location string) string =>
  'NET-${name}-${empty(location) ? '' : getLocationDisplayName(locationMap, location, true)}'

@export()
func getDPNETNetworkName(name string, locationMap object, location string) string =>
  'NET-${name}-${empty(location) ? '' : getLocationDisplayName(locationMap, location, true)}'
          
@export()
func getHUBNetworkName(name string, locationMap object, location string) string =>
  'HUB-${name}-${empty(location) ? '' : getLocationDisplayName(locationMap, location, true)}'

@export()
func getDCResourceGroupName(name string) string =>
  'DevCenter-${name}'

@export()
func getDPResourceGroupName(name string) string =>
  'DevProject-${name}'

@export()
func getDCNetworkAttachmentName(devCenterName string, networkConnectionId string) string =>
  'DC-${devCenterName}${substring(getResourceName(networkConnectionId), indexOf(getResourceName(networkConnectionId), '-'))}'

@export()
func getDPNetworkAttachmentName(devProjectName string, networkConnectionId string) string =>
  'DP-${devProjectName}${substring(getResourceName(networkConnectionId), indexOf(getResourceName(networkConnectionId), '-'))}'

@export()
func replaceResourceProvider(resourceId string, resourceProvider string) string =>
  join(concat(take(split(resourceId, '/'), 6), [resourceProvider], skip(split(resourceId, '/'), 8)), '/')
      