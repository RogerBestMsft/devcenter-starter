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

while getopts 'c:s:fb' OPT; do
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

	echo "Deploying DevProject '$CONFIGFILE' ..."
	az deployment sub create \
		--subscription "$SUBSCRIPTIONID" \
		--name $(uuidgen) \
		--location "$(az resource show --id $(jq --raw-output .devCenterId $CONFIGFILE) --query 'location' --output tsv)" \
		--template-file $SCRIPT_DIR/main.bicep \
		--only-show-errors \
		--parameters config=@$CONFIGFILE \
		--query properties.outputs > ${CONFIGFILE%.*}.output.json && echo "... done"

fi