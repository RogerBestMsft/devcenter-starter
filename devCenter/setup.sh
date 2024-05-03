#!/bin/bash

usage() { 
	echo "======================================================================================"
	echo "Usage: $0"
	echo "======================================================================================"
	echo " -s [REQUIRED]	Subscription Id"
	echo " -c [REQUIRED] 	Config file"
	exit 1; 
}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

while getopts 'c:s:g:fbr' OPT; do
    case "$OPT" in
		c)
			CONFIGFILE="${OPTARG}" ;;
		s)
			SUBSCRIPTIONID="${OPTARG}" ;;
		g)
			SECRETS="${OPTARG}" ;;
		*) 
			usage ;;
    esac
done


echo "Generating data files ..."; mkdir -p $SCRIPT_DIR/data
#[ -f $SCRIPT_DIR/data/secrets.json ] || (echo "{}" > $SCRIPT_DIR/data/secrets.json)
az account list-locations --query '[].{key: name, value: displayName}' | jq 'map( { (.key): .value }) | add' > $SCRIPT_DIR/data/locations.json
az role definition list --query '[].{ key: roleName, value: name}' | jq 'map( { (.key | gsub("\\s+";"") | ascii_downcase): .value }) | add' > $SCRIPT_DIR/data/roles.json
echo "... done"

echo "Deleting output files ..."
rm -f $SCRIPT_DIR/deploy.output.json
rm -f ${CONFIGFILE%.*}.output.json
echo "... done"

echo "Checking for DevCenter"
SUBSCRIPTIONID=$(jq --raw-output .subscription $CONFIGFILE)
DEVCENTERNAME=$(jq --raw-output .name $CONFIGFILE)
RESOURCEGROUPNAME=$(jq --raw-output .resourceGroupName $CONFIGFILE)
LOCATION=$(jq --raw-output .location $CONFIGFILE)

echo "Deploying to $SUBSCRIPTIONID, in $RESOURCEGROUPNAME for $DEVCENTERNAME at $LOCATION"
echo "... done"

echo "Create Resource Group $RESOURCEGROUPNAME"
if [ $(az group exists --name $RESOURCEGROUPNAME) = false ]; then
	echo "Creating resource group $RESOURCEGROUPNAME"
    az group create --name $RESOURCEGROUPNAME --location "$LOCATION" >/dev/null
fi
echo "... done"

echo "Enable DevCenter cli extension"
az extension add --name devcenter --allow-preview true
echo "... done"

echo "test $SECRETS"
NEW_SECRET=$($SECRETS | jq -R -s -c 'split("\n")[:-1]')
$NEW_SECRETS
echo "... done"

echo "Check for existance of Devcenter: $DEVCENTERNAME"
if [ $(az devcenter admin devcenter list --resource-group $RESOURCEGROUPNAME --subscription $SUBSCRIPTIONID --query "[?name=='$DEVCENTERNAME']") ]; then

	echo "Deploying DevCenter '$CONFIGFILE' ..."
	az deployment sub create \
		--subscription "$SUBSCRIPTIONID" \
		--name $(uuidgen) \
		--location "$LOCATION" \
		--template-file ./main.bicep \
		--only-show-errors \
		--parameters \
			config=@$CONFIGFILE \
			resolve=$RESOLVE \
			secrets=$NEW_SECRETS \
			windows365PrincipalId=$(az ad sp show --id 0af06dc6-e4b5-4f28-818e-e78e62d137a5 --query id --output tsv | dos2unix) \
		--query properties.outputs > ${CONFIGFILE%.*}.output.json && echo "... done"

fi