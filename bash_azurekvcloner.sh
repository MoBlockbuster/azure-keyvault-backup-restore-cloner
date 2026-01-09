#!/usr/bin/env bash
# Author on GitHub https://github.com/MoBlockbuster. Repo: https://github.com/MoBlockbuster/azure-keyvault-backup-cloner
# Clone keyvault objects into another keyvault in different region. 
# Example for mirroring: ./bash_azurekvcloner.sh -s xxxxx-xxxxxx-xxxxxx-xxxxx-xxxxx -k source-azure-keyvault-name -b target-azure-keyvault-name -i Client-ID -x Client-secret -t Tenant-ID

VERSION="2.0.0"
DATE=$(date +%Y.%m.%d_%H-%M)

while getopts :m:s:k:b:d:i:x:t:v opt
do
  case $opt in
       m) MODE=${OPTARG};;
       s) SUBSCRIPTION=${OPTARG};;
       k) SRC_KEYVAULT=${OPTARG};;
       b) DST_KEYVAULT=${OPTARG};;
       d) BACKUPDIR=${OPTARG};;
       i) CLIENTID=${OPTARG};;
       x) CLIENTSEC=${OPTARG};;
       t) TENANTID=${OPTARG};;
       v) echo "Version: $VERSION" && exit 0;;
       :) echo "YOU HAVE TO USE -m LIVE|STORE|RESTORE -s SUBSCRIPTION -k SOURCE KEYVAULTNAME -b DEST KEYVAULTNAME -d BACKUP_DIR_PATH -i CLIENTID -x CLIENTSEC -t TENANTID" && exit 1;;
       ?) echo "Parameter unknown. Use only -s SUBSCRIPTION -k SOURCE KEYVAULTNAME -b DEST KEYVAULTNAME -d BACKUP_DIR_PATH -i CLIENTID -x CLIENTSEC -t TENANTID" && exit 1;;
  esac
done

if [ $OPTIND -eq 1 ]; then
  echo "No options detected."
  exit 1
fi

if [[ -z $SUBSCRIPTION ]] || [[ -z $CLIENTID ]] || [[ -z $CLIENTSEC ]] || [[ -z $TENANTID ]] || [[ -z $MODE ]]
then
  echo "You have to use the -m MODE -s SUBSCRIPTION -k SOURCE KEYVAULTNAME -b DEST KEYVAULTNAME -d BACKUP_DIR_PATH -i CLIENTID -x CLIENTSEC -t TENANTID"
  exit 1
fi

azkv_clonemode()
{
KV_CERTS=$(az keyvault certificate list --vault-name $SRC_KEYVAULT --query "[].name" -o tsv --subscription $SUBSCRIPTION | tr '\n' ' ')
KV_SECRETS=$(az keyvault secret list --vault-name $SRC_KEYVAULT --query "[].name" -o tsv --subscription $SUBSCRIPTION | tr '\n' ' ')

echo "Detected certs: $KV_CERTS"
for cert in $KV_CERTS
do
  echo "Clone certificate: $cert"
  [[ $MODE == "STORE" ]] && az keyvault secret download --vault-name $SRC_KEYVAULT --name $cert --file $BACKUPDIR/$cert.pem --encoding utf-8
  [[ $MODE == "LIVE" ]] && az keyvault secret download --vault-name $SRC_KEYVAULT --name $cert --file .$cert.pem --encoding utf-8
  [[ $MODE == "LIVE" ]] && az keyvault certificate import --vault-name $DST_KEYVAULT --name $cert -f .$cert.pem --output none
  [[ $MODE == "LIVE" ]] && rm .$cert.pem -f
done
echo "Detected secrets: $KV_SECRETS"
for secret in $KV_SECRETS
do
  echo "Clone secret: $secret"
  AZ_SEC=$(az keyvault secret show --vault-name $SRC_KEYVAULT --name $secret --query value)
  [[ $MODE == "LIVE" ]] && az keyvault secret set --vault-name $DST_KEYVAULT --name $secret --value $AZ_SEC --output none
  [[ $MODE == "STORE" ]] && az keyvault secret show --vault-name $SRC_KEYVAULT --name $secret -o tsv --query "value" > $BACKUPDIR/$secret.sec
done
echo "Finish KeyVault cloner"
}

case "$MODE" in
  LIVE)
    echo "Run Azure KV cloner mode LIVE on $DATE"
    az login --service-principal -u "$CLIENTID" -p "$CLIENTSEC" -t "$TENANTID" -o none
    azkv_clonemode
    az logout
    ;;
  STORE)
    echo "Run Azure KV cloner mode STORE on $DATE"
    az login --service-principal -u "$CLIENTID" -p "$CLIENTSEC" -t "$TENANTID" -o none
    azkv_clonemode
    az logout
    ;;
  RESTORE)
    echo "Run Azure KV cloner mode RESTORE on $DATE"
    az login --service-principal -u "$CLIENTID" -p "$CLIENTSEC" -t "$TENANTID" -o none
    for cert_restore in $(ls $BACKUPDIR/*.pem)
    do
      echo "Restore certificate $cert_restore"
      az keyvault certificate import --vault-name $DST_KEYVAULT --name $(basename $cert_restore | cut -d '.' -f 1) -f $cert_restore --output none
    done
    for sec_restore in $(ls $BACKUPDIR/*.sec)
    do
      echo "Restore secret $sec_restore"
      SEC=$(cat $sec_restore)
      az keyvault secret set --vault-name $DST_KEYVAULT --name $(basename $sec_restore | cut -d '.' -f 1) --value $SEC --output none
    done
    ;;
esac
