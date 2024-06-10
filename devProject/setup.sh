#!/bin/bash

echo "Validating config '$1' ..."
if (cat $1 | jq -e . >/dev/null 2>&1); then
	echo "... done"
else
	echo "Config file $1 invalid !!!"
	exit $?
fi

echo "Generating data files ..."; mkdir -p ./data
az account list-locations --query '[].{key: name, value: displayName}' | jq 'map( { (.key): .value }) | add' > ./data/locations.json
az role definition list --query '[].{ key: roleName, value: name}' | jq 'map( { (.key | gsub("\\s+";"") | ascii_downcase): .value }) | add' > ./data/roles.json
echo "... done"

echo "Deleting output files ..."
rm -f ./deploy.output.json
rm -f ${1%.*}.output.json
echo "... done"

echo "Checking for DevCenter"
SUBSCRIPTIONID=$(jq --raw-output .subscription $1)
PROJECTNAME=$(jq --raw-output .name $1)
LOCATION=$(jq --raw-output .location $1)

echo "Deploying to $SUBSCRIPTIONID, $PROJECTNAME at $LOCATION"
echo "... done"

echo "Deploying DevProject '$1' ..."
az deployment sub create \
    --subscription "$SUBSCRIPTIONID" \
    --name $(uuidgen) \
    --location "$LOCATION" \
    --template-file ./main.bicep \
    --only-show-errors \
    --parameters \
        config=@$1 \
        resolve=$RESOLVE \
    --query properties.outputs > ${1%.*}.output.json && echo "... done"
