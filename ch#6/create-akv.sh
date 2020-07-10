keyVaultName="{keyvault-name}"
secret1Name="DatabaseLogin"
secret2Name="DatabasePassword"
secret3Name="Databaseserver"
secret4Name="Databasename"
secret1Alias="SQLUSER"
secret2Alias="SQLPASSWORD"
secret3Alias="SQLSERVER"
secret4Alias="SQLDBNAME"
location="westus"
resourceGroupName="teamResources"
aksName="allamrajuaks2"

adminSqlLogin="sqladminfXh8749"
password="cB8rk5Ru6"
FQDN="xxx.database.windows.net"
databaseName="mydrivingDB"

clientid="xxxxx-b38f-45f9-bb36-50c5df90c378"
secret="xxx.sxM8RVo9we844qhk~el_oTN~"

echo "Creating Key Vault..."

keyVault=az keyvault create -n $keyVaultName -g $resourceGroupName -l $location --enable-soft-delete true --retention-days 7 | ConvertFrom-Json
keyVault = (az keyvault show -n $keyVaultName | ConvertFrom-Json) # retrieve existing KV

echo "Creating Secrets in Key Vault..."

az keyvault secret set --name $secret1Name --value $adminSqlLogin --vault-name $keyVaultName #Username
az keyvault secret set --name $secret2Name --value $password --vault-name $keyVaultName #Password
az keyvault secret set --name $secret3Name --value $FQDN --vault-name $keyVaultName #server
az keyvault secret set --name $secret4Name --value $databaseName --vault-name $keyVaultName #dbname

az aks update-credentials --resource-group $resourceGroupName --name $aksName --reset-service-principal --service-principal $clientid --client-secret $secret

az ad app permission add --id $clientid --api 00000003-0000-0000-c000-000000000000 --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope 06da0dbc-49e2-44d2-8312-53f166ab848a=Scope 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role

az ad app permission grant --id $clientid --api 00000003-0000-0000-c000-000000000000

az ad app permission admin-consent --id $clientid

az keyvault set-policy -n $keyVaultName --spn $clientid --secret-permissions get list

# Create the Secret
kubectl create secret generic secrets-store-creds --from-literal clientid=$clientid --from-literal clientsecret=$secret -n api

# I was told we need to create 1 for each deployment so that the mount wont fail, not sure.
kubectl create secret generic secrets-store-creds-2 --from-literal=SQL_USER=$adminSqlLogin --from-literal=SQL_PASSWORD=$password  --from-literal=SQL_SERVER=$FQDN --from-literal=SQL_DBNAME=$databaseName -n api

#Install NGINX Ingress Conroller

helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update
helm install islamaks-ingress stable/nginx-ingress --namespace ingress-ns --set controller.replicaCount=1 --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux

#Getting the Ingress External-IP
kubectl --namespace ingress-ns get services -o wide -w islamaks-ingress-nginx-ingress-controller

# CSI Driver portions
echo "Adding Helm repo for Secret Store CSI..."
helm repo add secrets-store-csi-driver https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/master/charts

echo "Installing Secrets Store CSI Driver using Helm..."
kubectl create ns csi-driver
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --namespace csi-driver
kubectl get pods --namespace=csi-driver

echo "Installing Secrets Store CSI Driver with Azure Key Vault Provider..."
kubectl apply -f https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/deployment/provider-azure-installer.yaml -n csi-driver
kubectl get pods -n csi-driver
