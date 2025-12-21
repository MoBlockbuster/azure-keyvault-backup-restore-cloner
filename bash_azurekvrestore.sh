#!/usr/bin/env bash
# Author on GitHub https://github.com/MoBlockbuster. Repo: https://github.com/MoBlockbuster/azure-keyvault-backup-cloner
# Use first the bash_azurekvbackup.sh to backup a certain keyvault in Azure.
# Afterthat use this tool to restore certs with *.certbackup, *.secbackup for secrets and *.keybackup for keys
# Example: ./bash_azurekvrestore.sh -m MODE -s XXXXXX-XXXXXXXX-XXXXXXX-XXXXXXXX -k KEYVAULTNAME -d RESTOREDIR with backupfiles -i ID of AZURE CLIENT-ID -x AZURE CLIENT-SECRET -t AZURE TENANT-ID -a STORAGEACCOUNT -c CONTAINERNAME -b BACKUPNAME.tar.gz

VERSION="1.0.0"
DATE=$(date +%Y.%m.%d_%H-%M)

while getopts :m:s:k:d:i:x:t:va:c:b: opt
do
  case $opt in
    m) MODE=${OPTARG};;
    s) SUBSCRIPTION=${OPTARG};;
    k) KEYVAULT=${OPTARG};;
    d) RESTOREDIR=${OPTARG};;
    i) CLIENTID=${OPTARG};;
    x) CLIENTSEC=${OPTARG};;
    t) TENANTID=${OPTARG};;
    v) echo "Version: $VERSION" && exit 0;;
    a) STORAGEACCOUNT=${OPTARG};;
    c) CONTAINER=${OPTARG};;
    b) AZ_KVBACKUP=${OPTARG};;
    :) echo "YOU HAVE TO USE -m MODE -s SUBSCRIPTION -k KEYVAULTNAME -d RESTORE_DIR_PATH -i ID of AZURE CLIENT-ID -x AZURE CLIENT-SECRET -t AZURE TENANT-ID -a STORAGEACCOUNT -c CONTAINER -b BACKUPNAME.tar.gz" && exit 1;;
    ?) echo "Parameter unknown. Use only -m MODE -s SUBSCRIPTION, -k KEYVAULTNAME and -d RESTORE_DIR_PATH -i ID of AZURE CLIENT-ID -x AZURE CLIENT-SECRET -t AZURE TENANT-ID -a STORAGEACCOUNT -c CONTAINER -b BACKUPNAME.tar.gz" && exit 1;;
  esac
done

if [ $OPTIND -eq 1 ]; then
  echo "No options detected. YOU HAVE TO USE -m MODE -s SUBSCRIPTION, -k KEYVAULTNAME and -d RESTORE_DIR_PATH -i ID of AZURE CLIENT-ID -x AZURE CLIENT-SECRET -t AZURE TENANT-ID -a STORAGEACCOUNT -c CONTAINER -b BACKUPNAME.tar.gz"
  exit 1
fi

azkv_restore()
{
  for file in $(ls $RESTOREDIR)
  do
    echo "Restore file: $file"
    TYP="${file##*.}"
    if [ $TYP == "certbackup" ]
    then
      az keyvault certificate restore --file $RESTOREDIR/$file --vault-name $KEYVAULT --output none
    fi
    if [ $TYP == "secbackup" ]
    then
      az keyvault secret restore --file $RESTOREDIR/$file --vault-name $KEYVAULT --output none
    fi
    if [ $TYP == "keybackup" ]
    then
      az keyvault key restore --file $RESTOREDIR/$file --vault-name $KEYVAULT --output none
    fi
  done
}

case "$MODE" in
  LOCAL)
    echo "Run Azure KV restore mode LOCAL on $DATE"
    az login --service-principal -u "$CLIENTID" -p "$CLIENTSEC" -t "$TENANTID" -o none
    azkv_restore
    az logout
    ;;
  STORAGE)
    echo "Run Azure KV restore mode STORAGE on $DATE"
    if [[ -z $STORAGEACCOUNT ]] || [[ -z $CONTAINER ]] || [[ -z $AZ_KVBACKUP ]]
    then
      echo "You have to use the -a STORAGEACCOUNTNAME,-c CONTAINERNAME and -b BACKUPNAME.tar.gz with mode STORAGE"
      exit 1
    fi
    az login --service-principal -u "$CLIENTID" -p "$CLIENTSEC" -t "$TENANTID" -o none
    az storage blob download --account-name $STORAGEACCOUNT --container-name $CONTAINER --name $AZ_KVBACKUP --file $RESTOREDIR/$AZ_KVBACKUP --auth-mode login --output none
    tar -xzvf $RESTOREDIR/$AZ_KVBACKUP
    azkv_restore
    rm $RESTOREDIR/$AZ_KVBACKUP -f
    rm $RESTOREDIR/*.certbackup -f
    rm $RESTOREDIR/*.keybackup -f
    rm $RESTOREDIR/*.secbackup -f
    az logout
    ;;
esac
