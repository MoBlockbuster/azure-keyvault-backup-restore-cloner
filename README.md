# Azure-Keyvault-Backup-Restore-Cloner
Hi Azure family! This tool allows you to backup and restore your Azure Key Vault objects or clone Key Vault objects into another Key Vault, even in a different region.

Azure does not support restoring Key Vault objects into a different region. Therefore, you can use bash_azurekvcloner.sh or ps1_azurekvcloner.sh to automatically mirror certificates and secrets from one Key Vault to another in a different region.

**Note**: It is currently not possible in Azure to mirror keys into another Key Vault. You can use xxx_azurekvbackup.sh to create a backup and xxx_azurekvrestore.sh to restore keys in the same region.

## Requirements
* azcli
* Azure Service principal
* Azure permission for service principle on each keyvault: 
    * Key Vault Certificates Officer 
    * Key Vault Crypt Officer 
    * Key Vault Secrets Officer
* Azure permission for service principle on each storageaccount container to store the backups:
    * Storage Blob Data Contributor
* Azure permission for service principle on each storageaccount container to restore the backups: 
    * Storage Blob Data Reader

## Bash: backup

Use **MODE** = **LOCAL** to store the keyvault objects local on the machine

Use **MODE** = **STORAGE** to store the keyvault objects into an azure storageaccount

```
./bash_azurekvbackup.sh -m MODE -s xxxxx-xxxxxx-xxxxxx-xxxxx-xxxxx -k azure-keyvault-name -d /my/backup/path -i Client-ID -x Client-secret -t Tenant-ID -l LOGFILE

Example:

bash_azurekvbackup.sh -m LOCAL -s xxxxx-xxxxxx-xxxxxx-xxxxx-xxxxx -k azure-keyvault-name -d /my/backup/path -i Client-ID -x Client-secret -t Tenant-ID -l /my/backup/path/kvbackup.log 

bash_azurekvbackup.sh -m STORAGE -s xxxxx-xxxxxx-xxxxxx-xxxxx-xxxxx -k azure-keyvault-name -d /my/backup/path -i Client-ID -x Client-secret -t Tenant-ID -l /my/backup/path/kvbackup.log -a STORAGEACCOUNTNAME -c CONTAINERNAME
```

## Bash: restore

Use **MODE** = **LOCAL** to restore local keyvault objects into a keyvault

Use **MODE** = **STORAGE** to restore from azure storageaccount

```
./bash_azurekvrestore.sh -m MODE -s xxxxx-xxxxxx-xxxxxx-xxxxx-xxxxx -k azure-keyvault-name -d /my/restore/path -i Client-ID -x Client-secret -t Tenant-ID

Example:

./bash_azurekvrestore.sh -m LOCAL -s xxxxx-xxxxxx-xxxxxx-xxxxx-xxxxx -k azure-keyvault-name -d /my/backup/path -i Client-ID -x Client-secret -t Tenant-ID

./bash_azurekvrestore.sh -m STORAGE -s xxxxx-xxxxxx-xxxxxx-xxxxx-xxxxx -k azure-keyvault-name -d /my/backup/path -i Client-ID -x Client-secret -t Tenant-ID -a STORAGEACCOUNTNAME -c CONTAINERNAME -b BACKUPNAME.tar.gz

-b must be the backupfile from bash_azurekvbackup.sh or ps1_azurekvbackup.sh
```

## Clone Key Vault objects into another Key Vault in a different Region
**Note**: Currently it is not possible to clone keys. This is an Azure limitation.

```
./bash_azurekvcloner.sh -s xxxxx-xxxxxx-xxxxxx-xxxxx-xxxxx -k source-azure-keyvault-name -b target-azure-keyvault-name -i Client-ID -x Client-secret -t Tenant-ID
```
