#!/bin/bash

usage() { 
	echo "======================================================================================"
	echo "Usage: $0"
	echo "======================================================================================"
	echo " -s [REQUIRED]	Subscription Id"
	echo " -c [REQUIRED] 	Config file"
	echo " -f [SWITCH]      Force deployment by purging deleted resources first"
	echo " -b [SWITCH]      Build instead of deploy the bicep template"
	exit 1; 
}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
FORCE=false
BUILD=false

while getopts 'c:s:f' OPT; do
    case "$OPT" in
		c)
			CONFIGFILE="${OPTARG}" ;;
		s)
			SUBSCRIPTIONID="${OPTARG}" ;;
		f)
			FORCE=true ;;
		b)
			BUILD=true ;;
		*) 
			usage ;;
    esac
done

if $FORCE; then

	echo "Purging deleted resources ..."

	for KEYVAULT in $(az keyvault list-deleted --subscription $SUBSCRIPTIONID --resource-type vault --query '[?not_null(properties.purgeProtectionEnabled, false) == false].name' --output tsv | dos2unix); do
		echo "$SUBSCRIPTIONID - Purging deleted key vault '$KEYVAULT' ..." 
		az keyvault purge --subscription $SUBSCRIPTIONID --name $KEYVAULT -o none & 
	done

	for APPCONFIG in $(az appconfig list-deleted --subscription $SUBSCRIPTIONID --query '[].name' --output tsv | dos2unix); do
		echo "$SUBSCRIPTIONID - Purging deleted app configuration '$APPCONFIG' ..." 
		az appconfig purge --subscription $SUBSCRIPTIONID --name $APPCONFIG --yes -o none &
	done

	wait; echo "... done"
fi

echo "Generating data files ..."; mkdir -p $SCRIPT_DIR/data
[ -f $SCRIPT_DIR/data/secrets.json ] || (echo "{}" > $SCRIPT_DIR/data/secrets.json)
az account list-locations --query '[].{key: name, value: displayName}' | jq 'map( { (.key): .value }) | add' > $SCRIPT_DIR/data/locations.json
echo "... done"

echo "Deleting output files ..."
rm -f $SCRIPT_DIR/deploy.output.json
rm -f ${CONFIGFILE%.*}.output.json
echo "... done"

if $BUILD; then

	echo "Building deployment template ..."
	az bicep build \
		--file ./main.bicep \
		--outfile $SCRIPT_DIR/deploy.output.json \
		--only-show-errors && echo "... done" || exit $?

else

	echo "Deploying DevCenter '$CONFIGFILE' ..."; az deployment sub create \
		--subscription "$SUBSCRIPTIONID" \
		--name $(uuidgen) \
		--location "$(jq --raw-output .location $CONFIGFILE)" \
		--template-file ./main.bicep \
		--only-show-errors \
		--parameters \
			config=@$CONFIGFILE \
			secrets=@$SCRIPT_DIR/data/secrets.json \
			windows365PrincipalId=$(az ad sp show --id 0af06dc6-e4b5-4f28-818e-e78e62d137a5 --query id --output tsv | dos2unix) \
		--query properties.outputs > ${CONFIGFILE%.*}.output.json

fi