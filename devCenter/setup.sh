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

while getopts 'c:s:fbr' OPT; do
    case "$OPT" in
		c)
			CONFIGFILE="${OPTARG}" ;;
		s)
			SUBSCRIPTIONID="${OPTARG}" ;;
		*) 
			usage ;;
    esac
done


echo "Generating data files ..."; mkdir -p $SCRIPT_DIR/data
[ -f $SCRIPT_DIR/data/secrets.json ] || (echo "{}" > $SCRIPT_DIR/data/secrets.json)
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
if $(az devcenter admin devcenter show --name $DEVCENTERNAME --resource-group $RESOURCEGROUPNAME --subscription $SUBSCRIPTIONID); then

	echo "Deploying DevCenter '$CONFIGFILE' ..."
	az deployment sub create \
		--subscription "$SUBSCRIPTIONID" \
		--name $(uuidgen) \
		--location "$(jq --raw-output .location $CONFIGFILE)" \
		--template-file ./main.bicep \
		--only-show-errors \
		--parameters \
			config=@$CONFIGFILE \
			resolve=$RESOLVE \
			secrets=@$SCRIPT_DIR/data/secrets.json \
			windows365PrincipalId=$(az ad sp show --id 0af06dc6-e4b5-4f28-818e-e78e62d137a5 --query id --output tsv | dos2unix) \
		--query properties.outputs > ${CONFIGFILE%.*}.output.json && echo "... done"

fi