@export()
func generalizeLocation(location string) string => 
  toLower(replace(location, ' ', ''))

@export()
func getLocationDisplayName(locationMap object, location string, removeBlanks bool) string => 
  replace(first(filter(items(locationMap), item => item.key == generalizeLocation(location))).value, (removeBlanks ? ' ' : '') , '')

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
  union(values, values)
