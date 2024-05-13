#!/bin/bash

usage() { 
	echo "======================================================================================"
	echo "Usage: $0"
	echo "======================================================================================"
	echo " -c [REQUIRED] 	Config file"
	echo " -s [REQUIRED]	SECRETSFILE"
	exit 1; 
}

while getopts 'c:s' OPT; do
    case "$OPT" in
		c)
			CONFIGFILE="${OPTARG}" ;;
		s)
			SECRETSFILE="${OPTARG}" ;;
		*) 
			usage ;;
    esac
done

echo "Generating data files ..."; mkdir -p ./data

echo "Check SecretsFile" 
#[ -f $SECRETSFILE ] || (echo "{}" > $SECRETSFILE)
echo "x $1"
echo "y $2"
XXX=$(echo $2 | base64 --decode)
echo "z $XXX"


az account list-locations --query '[].{key: name, value: displayName}' | jq 'map( { (.key): .value }) | add' > ./data/locations.json
az role definition list --query '[].{ key: roleName, value: name}' | jq 'map( { (.key | gsub("\\s+";"") | ascii_downcase): .value }) | add' > ./data/roles.json
echo "... done"

echo "Deleting output files ..."
rm -f ./deploy.output.json
rm -f ${CONFIGFILE%.*}.output.json
echo "... done"

echo "Checking for DevCenter"
SUBSCRIPTIONID=$(jq --raw-output .subscription $CONFIGFILE)
DEVCENTERNAME=$(jq --raw-output .name $CONFIGFILE)
LOCATION=$(jq --raw-output .location $CONFIGFILE)

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
		secrets=@$XXX \
		windows365PrincipalId=$(az ad sp show --id 0af06dc6-e4b5-4f28-818e-e78e62d137a5 --query id --output tsv | dos2unix) \
	--query properties.outputs > ${CONFIGFILE%.*}.output.json && echo "... done"