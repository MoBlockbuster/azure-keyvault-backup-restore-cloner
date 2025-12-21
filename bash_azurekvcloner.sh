#!/usr/bin/env bash
# Author on GitHub https://github.com/MoBlockbuster. Repo: https://github.com/MoBlockbuster/azure-keyvault-backup-cloner
# Clone keyvault objects into another keyvault in different region. 
# Example for mirroring: ./bash_azurekvcloner.sh -s xxxxx-xxxxxx-xxxxxx-xxxxx-xxxxx -k source-azure-keyvault-name -b target-azure-keyvault-name -i Client-ID -x Client-secret -t Tenant-ID

VERSION="1.0.0"
DATE=$(date +%Y.%m.%d_%H-%M)

while getopts :s:k:b:d:i:x:t: opt
do
  case $opt in
       s) SUBSCRIPTION=${OPTARG};;
       k) SRC_KEYVAULT=${OPTARG};;
       b) DST_KEYVAULT=${OPTARG};;
       d) BACKUPDIR=${OPTARG};;
       i) CLIENTID=${OPTARG};;
       x) CLIENTSEC=${OPTARG};;
       t) TENANTID=${OPTARG};;
       :) echo "YOU HAVE TO USE -m LIVE|STORE -s SUBSCRIPTION -k SOURCE KEYVAULTNAME -b DEST KEYVAULTNAME -d BACKUP_DIR_PATH -i CLIENTID -x CLIENTSEC -t TENANTID" && exit 1;;
       ?) echo "Parameter unknown. Use only -s SUBSCRIPTION -k SOURCE KEYVAULTNAME -b DEST KEYVAULTNAME -d BACKUP_DIR_PATH -i CLIENTID -x CLIENTSEC -t TENANTID" && exit 1;;
  esac
done

if [ $OPTIND -eq 1 ]; then
  echo "No options detected."
  exit 1
fi

if [[ -z $SUBSCRIPTION ]] || [[ -z $SRC_KEYVAULT ]] || [[ -z $DST_KEYVAULT ]] || [[ -z $BACKUPDIR ]] || [[ -z $CLIENTID ]] || [[ -z $CLIENTSEC ]] || [[ -z $TENANTID ]]
then
  echo "You have to use the -s SUBSCRIPTION -k SOURCE KEYVAULTNAME -b DEST KEYVAULTNAME -d BACKUP_DIR_PATH -i CLIENTID -x CLIENTSEC -t TENANTID"
  exit 1
fi

echo "Run Azure KV cloner on $DATE"
az login --service-principal -u "$CLIENTID" -p "$CLIENTSEC" -t "$TENANTID" -o none

KV_CERTS=$(az keyvault certificate list --vault-name $SRC_KEYVAULT --query "[].name" -o tsv --subscription $SUBSCRIPTION | tr '\n' ' ')
KV_SECRETS=$(az keyvault secret list --vault-name $SRC_KEYVAULT --query "[].name" -o tsv --subscription $SUBSCRIPTION | tr '\n' ' ')

echo "Detected certs: $KV_CERTS"
for cert in $KV_CERTS
do
  echo "Clone certificate: $cert"
  az keyvault secret download --vault-name $SRC_KEYVAULT --name $cert --file $BACKUPDIR/$cert.pem --encoding utf-8
  az keyvault certificate import --vault-name $DST_KEYVAULT --name $cert -f $BACKUPDIR/$cert.pem --output none
  rm $BACKUPDIR/$cert.pem -f
done
echo "Detected secrets: $KV_SECRETS"
for secret in $KV_SECRETS
do
  echo "Clone secret: $secret"
  AZ_SEC=$(az keyvault secret show --vault-name $SRC_KEYVAULT --name $secret --query value)
  az keyvault secret set --vault-name $DST_KEYVAULT --name $secret --value $AZ_SEC --output none
done
echo "Finish KeyVault cloner"
az logout
