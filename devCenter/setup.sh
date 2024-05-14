#!/bin/bash

echo "Validating config '$1' ..."
if (cat $1 | jq -e . >/dev/null 2>&1); then
	echo "... done"
else
	echo "Config file $1 invalid !!!"
	exit $?
fi


echo "Generating data files ..."; mkdir -p ./data

echo "Generate support files." 
az account list-locations --query '[].{key: name, value: displayName}' | jq 'map( { (.key): .value }) | add' > ./data/locations.json
az role definition list --query '[].{ key: roleName, value: name}' | jq 'map( { (.key | gsub("\\s+";"") | ascii_downcase): .value }) | add' > ./data/roles.json
echo "... done"

echo "Deleting output files ..."
rm -f ./deploy.output.json
rm -f ${1%.*}.output.json
echo "... done"

echo "Checking for DevCenter"
SUBSCRIPTIONID=$(jq --raw-output .subscription $1)
DEVCENTERNAME=$(jq --raw-output .name $1)
LOCATION=$(jq --raw-output .location $1)
echo "Location $LOCATION"


echo "Deploying DevCenter '$1' ..."
az deployment sub create \
	--subscription "$SUBSCRIPTIONID" \
	--name $(uuidgen) \
	--location "$LOCATION" \
	--template-file ./main.bicep \
	--only-show-errors \
	--parameters \
		config=@$1 \
		resolve=$RESOLVE \
		secrets=@$(echo $2) \
		windows365PrincipalId=$(az ad sp show --id 0af06dc6-e4b5-4f28-818e-e78e62d137a5 --query id --output tsv | dos2unix) \
	--query properties.outputs > ${1%.*}.output.json && echo "... done"