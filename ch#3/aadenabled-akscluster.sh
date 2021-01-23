
#Here are the steps to create an AKS Cluster with Azure Active Directory Integration.
https://docs.microsoft.com/en-us/azure/aks/managed-aad

# Create an Azure AD group
az ad group create --display-name myAKSAdminGroup --mail-nickname myAKSAdminGroup

# List existing groups in the directory
az ad group list --filter "displayname eq 'myAKSAdminGroup'" -o table

#Create an AKS cluster with AAD and Managed Identity 
az aks create -g rg-containerOH \
-n MyAADAKSCluster --enable-aad \
--aad-admin-group-object-ids 12f09079-2d28-4fff-b78e-b741db0c7cb6 --aad-tenant-id 874fdfaa-1983-4571-8766-a525025d2537 --enable-managed-identity

#Access an Azure AD enabled cluster
az aks get-credentials --resource-group rg-containerOH --name MyAADAKSCluster

#Get nodes of AKS cluster
kubectl get nodes

#######It should fail for you.########


#You'll need the Azure Kubernetes Service Cluster Admin or User built-in role  to do the following steps.

#Assign role permissions to a user or group 
# Get the resource ID of your AKS cluster
AKS_CLUSTER=$(az aks show --resource-group rg-containerOH --name MyAADAKSCluster --query id -o tsv)

#Somehow this didn't work well in bash shell. In that case get the output of
#az aks show --resource-group rg-containerOH --name MyManagedCluster --query id -o tsv and store it in AKS_CLUSTER variable

# Get the account credentials for the logged in user. This could be hacker1 or 2 or 3 that can act as a Cluster Admin 

ACCOUNT_UPN=$(az account show --query user.name -o tsv)
ACCOUNT_ID=$(az ad user show --id $ACCOUNT_UPN --query objectId -o tsv)

# Assign the 'Cluster Admin' role to the user (kaaks)
az role assignment create \
    --assignee $ACCOUNT_ID \
    --scope $AKS_CLUSTER \
    --role "Azure Kubernetes Service Cluster Admin Role"

#Access an Azure AD enabled cluster
az aks get-credentials --resource-group rg-containerOH --name MyAADAKSCluster

#Get nodes of AKS cluster
kubectl get nodes
