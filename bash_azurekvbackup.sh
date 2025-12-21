#!/usr/bin/env bash
# Author on GitHub https://github.com/MoBlockbuster Repo:  https://github.com/MoBlockbuster/azure-keyvault-backup-cloner
# Add this tool into a regular runner like cronjob or Azure DevOps Pipeline for daily Azure Keyvault backups
# Example: ./bash_azurekvbackup.sh -s XXXXXX-XXXXXXXX-XXXXXXX-XXXXXXXX -k KEYVAULTNAME -d BACKUPDIR to store the backups -i ID of AZURE CLIENT-ID -x AZURE CLIENT-SECRET -t AZURE TENANT-ID -l LOGILE

VERSION="1.0.0"
DATE=$(date +%Y.%m.%d_%H-%M)

while getopts :m:s:k:d:i:x:t:l:va:c: opt
do
  case $opt in
    m) MODE=${OPTARG};;
    s) SUBSCRIPTION=${OPTARG};;
    k) KEYVAULT=${OPTARG};;
    d) BACKUPDIR=${OPTARG};;
    i) CLIENTID=${OPTARG};;
    x) CLIENTSEC=${OPTARG};;
    t) TENANTID=${OPTARG};;
    l) LOGFILE=${OPTARG};;
    v) echo "Version: $VERSION" && exit 0;;
    a) STORAGEACCOUNT=${OPTARG};;
    c) CONTAINER=${OPTARG};;
    :) echo "YOU HAVE TO USE -m MODE -s SUBSCRIPTION -k KEYVAULTNAME -d BACKUP_DIR_PATH -i ID of AZURE CLIENT-ID -x AZURE CLIENT-SECRET -t AZURE TENANT-ID -l LOGFILE -a STORAGEACCOUNT -c CONTAINER" && exit 1;;
    ?) echo "Parameter unknown. Use only -m MODE -s SUBSCRIPTION -k KEYVAULTNAME -d BACKUP_DIR_PATH -i ID of AZURE CLIENT-ID -x AZURE CLIENT-SECRET -t AZURE TENANT-ID -l LOGFILE -a STORAGEACCOUNT -c CONTAINER" && exit 1;;
  esac
done

if [ $OPTIND -eq 1 ]; then
  echo "No options detected. YOU HAVE TO USE -m MODE -s SUBSCRIPTION, -k KEYVAULTNAME and -d BACKUP_DIR_PATH -i ID of AZURE CLIENT-ID -x AZURE CLIENT-SECRET -t AZURE TENANT-ID -l LOGFILE -a STORAGEACCOUNT -c CONTAINER"
  exit 1
fi

if [[ -z $SUBSCRIPTION ]] || [[ -z $KEYVAULT ]] || [[ -z $BACKUPDIR ]] || [[ -z $CLIENTID ]] || [[ -z $CLIENTSEC ]] || [[ -z $TENANTID ]]
then
  echo "You have to use the -m MODE -s SUBSCRIPTION, -k KEYVAULTNAME and -d BACKUP_DIR_PATH -i CLIENT-ID -x CLIENT-SECRET -t TENANT-ID"
  exit 1
fi

LOGFILE="${LOGFILE:=/dev/null}"

azkv_backup()
{
  KV_CERTS=$(az keyvault certificate list --vault-name $KEYVAULT --query "[].name" -o tsv --subscription $SUBSCRIPTION | tr '\n' ' ')
  KV_SECRETS=$(az keyvault secret list --vault-name $KEYVAULT --query "[].name" -o tsv --subscription $SUBSCRIPTION | tr '\n' ' ')
  KV_KEY=$(az keyvault key list --vault-name $KEYVAULT --query "[].name" -o tsv --subscription $SUBSCRIPTION | tr '\n' ' ')
  echo "Detected certs: $KV_CERTS"
   for cert in $KV_CERTS
   do
     echo "Backup certificate: $cert" >> $LOGFILE
     az keyvault certificate backup --file $BACKUPDIR/$cert.certbackup --name $cert --vault-name $KEYVAULT
   done
   echo "Detected secrets: $KV_SECRETS"
   for secret in $KV_SECRETS
   do
     echo "Backup secret: $secret" >> $LOGFILE
     az keyvault secret backup --file $BACKUPDIR/$cert.secbackup --name $secret --vault-name $KEYVAULT
   done
   echo "Detected keys: $KV_KEY"
   for key in $KV_KEY
   do
     echo "Backup key: $key" >> $LOGFILE
     az keyvault key backup --file $BACKUPDIR/$key.keybackup --name $key --vault-name $KEYVAULT
   done
   echo -e "Finish KeyVault backup\n\n" >> $LOGFILE
}

case "$MODE" in
  LOCAL)
    echo "Run Azure KV backup mode LOCAL on $DATE" >> $LOGFILE
    az login --service-principal -u "$CLIENTID" -p "$CLIENTSEC" -t "$TENANTID" -o none
    azkv_backup
    az logout
    ;;
  STORAGE)
    echo "Run Azure KV backup mode STORAGE on $DATE" >> $LOGFILE
    if [[ -z $STORAGEACCOUNT ]] || [[ -z $CONTAINER ]]
    then
      echo "You have to use the -a STORAGEACCOUNTNAME and -c CONTAINERNAME with mode STORAGE"
      exit 1
    fi
    az login --service-principal -u "$CLIENTID" -p "$CLIENTSEC" -t "$TENANTID" -o none
    azkv_backup
    tar -czvf $BACKUPDIR/azure_kvbackup_$DATE.tar.gz $BACKUPDIR/*
    az storage blob upload --account-name $STORAGEACCOUNT --container-name $CONTAINER --name azure_kvbackup_$DATE.tar.gz --file $BACKUPDIR/azure_kvbackup_$DATE.tar.gz --auth-mode login --output none
    rm $BACKUPDIR/azure_kvbackup_$DATE.tar.gz -f
    rm $BACKUPDIR/*.certbackup -f
    rm $BACKUPDIR/*.keybackup -f
    rm $BACKUPDIR/*.secbackup -f
    az logout
    ;;
  "")
    echo "You have to use mode LOCAL or STORAGE"
    exit 1
    ;;
  *)
    echo "Unknown mode: $MODE"
    exit 1
    ;;
esac
