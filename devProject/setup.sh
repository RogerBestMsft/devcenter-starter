#!/bin/bash

usage() { 
	echo "======================================================================================"
	echo "Usage: $0"
	echo "======================================================================================"
	echo " -c [REQUIRED] 	Config file"
    echo " -s [REQUIRED]    Secrets"
	exit 1; 
}

while getopts 'c:s' OPT; do
    case "$OPT" in
		c)
			CONFIGFILE="${OPTARG}" ;;
		s)			
			SECRETS="${OPTARG}" ;;
		*) 
			usage ;;
    esac
done

echo "Validating config '$CONFIGFILE' ..."
if (cat $CONFIGFILE | jq -e . >/dev/null 2>&1); then
	echo "... done"
else
	echo "Config file $CONFIGFILE invalid !!!"
	exit $?
fi

echo "Generating data files ..."; mkdir -p ./data
echo "X - $SECRETS"
[ -f $SECRETS ] || (echo "{}" > $SECRETS)
az account list-locations --query '[].{key: name, value: displayName}' | jq 'map( { (.key): .value }) | add' > ./data/locations.json
az role definition list --query '[].{ key: roleName, value: name}' | jq 'map( { (.key | gsub("\\s+";"") | ascii_downcase): .value }) | add' > ./data/roles.json
echo "... done"

echo "Deleting output files ..."
rm -f ./deploy.output.json
rm -f ${CONFIGFILE%.*}.output.json
echo "... done"

echo "Checking for DevCenter"
SUBSCRIPTIONID=$(jq --raw-output .subscription $CONFIGFILE)
PROJECTNAME=$(jq --raw-output .name $CONFIGFILE)
LOCATION=$(jq --raw-output .location $CONFIGFILE)

echo "Deploying to $SUBSCRIPTIONID, $PROJECTNAME at $LOCATION"
echo "... done"

echo "TEST S"
echo $SECRETS

echo "Deploying DevProject '$CONFIGFILE' ..."
az deployment sub create \
    --subscription "$SUBSCRIPTIONID" \
    --name $(uuidgen) \
    --location "$LOCATION" \
    --template-file ./main.bicep \
    --only-show-errors \
    --parameters \
        config=@$CONFIGFILE \
        resolve=$RESOLVE \
        secrets=@$SECRETS \
    --query properties.outputs > ${CONFIGFILE%.*}.output.json && echo "... done"
