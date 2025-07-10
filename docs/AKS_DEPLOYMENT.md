# Azure Kubernetes Service (AKS) Deployment Guide

This guide provides step-by-step instructions for setting up and deploying the HomeCare application to Azure Kubernetes Service using GitHub Actions with OIDC authentication.

## Prerequisites

- Azure CLI installed and configured
- kubectl installed
- An Azure subscription with appropriate permissions
- A GitHub repository with admin access

## Part 1: Azure Infrastructure Setup

### Option A: Automated Setup (Recommended)

Use the provided Terraform configuration and NGINX ingress scripts for automated setup:

```bash
# Initialize Terraform infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# Install NGINX Ingress Controller
./scripts/install-nginx-ingress.sh
```

The script will:
- Check for existing resources and skip creation if they exist
- Create resource group and AKS cluster with optimal settings
- Install NGINX Ingress Controller for cost-effective load balancing
- Create Azure AD app registration with OIDC
- Configure all necessary permissions and federated identity credentials
- Generate configuration file with all required values
- Provide DNS configuration instructions

### Option B: Manual Setup

If you prefer manual setup, follow these steps:

### 1.1 Create Resource Group

```bash
# Set variables
RESOURCE_GROUP="homecare-rg"
LOCATION="eastus"
CLUSTER_NAME="homecare-aks"
APP_NAME="homecare-app"
VNET_NAME="homecare-vnet"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 1.2 Create AKS Cluster

Create the Azure Kubernetes Service cluster:

Create AKS cluster with optimized settings for single node:

```bash
# Create AKS cluster with minimal resources for free tier
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count 1 \
  --node-vm-size Standard_D2plds_v5 \
  --enable-managed-identity \
  --generate-ssh-keys \
  --tier free \
  --network-plugin azure \
  --network-plugin-mode overlay
```

### 1.3 Install NGINX Ingress Controller

Install NGINX Ingress Controller for cost-effective load balancing:

```bash
# Install NGINX Ingress Controller using the provided script
./scripts/install-nginx-ingress.sh

# Or install manually with Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-sku"="basic"
```
  --appgw-name homecare-appgw
```

## Part 2: Azure AD App Registration & OIDC Setup

**Note**: The provided setup script (`scripts/setup-aks.sh`) automatically handles resource creation and checks for existing resources to avoid conflicts.

### 2.1 Create Azure AD App Registration

```bash
# Create the app registration
APP_ID=$(az ad app create --display-name "homecare-github-actions" --query appId --output tsv)
echo "App ID: $APP_ID"

# Create service principal
az ad sp create --id $APP_ID

# Get tenant ID
TENANT_ID=$(az account show --query tenantId --output tsv)
echo "Tenant ID: $TENANT_ID"

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"
```

### 2.2 Assign Permissions

```bash
# Assign Contributor role to the resource group
az role assignment create \
  --role Contributor \
  --assignee $APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

# Assign AKS Cluster User role
az role assignment create \
  --role "Azure Kubernetes Service Cluster User Role" \
  --assignee $APP_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME"
```

### 2.3 Configure Federated Identity Credentials

```bash
# For main branch deployments
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "homecare-main-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_GITHUB_USERNAME/homecare:ref:refs/heads/main",
    "description": "Main branch deployment",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For release deployments
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "homecare-releases",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_GITHUB_USERNAME/homecare:ref:refs/tags/*",
    "description": "Release deployment",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For manual workflow dispatch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "homecare-workflow-dispatch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_GITHUB_USERNAME/homecare:ref:refs/heads/main",
    "description": "Manual workflow dispatch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For any branch deployments
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "homecare-branches",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_GITHUB_USERNAME/homecare:ref:refs/heads/*",
    "description": "All branch deployments",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

**Important**: Replace `YOUR_GITHUB_USERNAME` with your actual GitHub username.

## Part 3: GitHub Repository Configuration

### 3.1 Create GitHub Environments

1. Go to your GitHub repository
2. Navigate to **Settings** → **Environments**
3. Create two environments:
   - `dev` (for development deployments)
   - `prod` (for production deployments)

### 3.2 Configure Repository Secrets

Add the following secrets to your repository (**Settings** → **Secrets and variables** → **Actions**):

#### Repository-level secrets:
- `AZURE_CLIENT_ID`: The App ID from step 2.1
- `AZURE_TENANT_ID`: The Tenant ID from step 2.1
- `AZURE_SUBSCRIPTION_ID`: The Subscription ID from step 2.1
- `AZURE_RESOURCE_GROUP`: Your resource group name (e.g., `homecare-rg`)
- `AZURE_CLUSTER_NAME`: Your AKS cluster name (e.g., `homecare-aks`)

#### Environment-specific secrets:
Configure these for each environment (`dev` and `prod`):

**For `dev` environment:**
- No additional secrets needed for basic setup

**For `prod` environment:**
- Consider adding production-specific configurations if needed

### 3.3 Update Domain Configuration

Update the ingress configuration files with your actual domain:

The ingress is pre-configured for the `homecareapp.xyz` domain:

- **Production**: `homecareapp.xyz`
- **Development**: `dev.homecareapp.xyz`

No manual ingress file updates are needed.

## Part 4: Deployment

### 4.1 Manual Deployment

1. Go to your GitHub repository
2. Navigate to **Actions** tab
3. Select **Deploy to AKS** workflow
4. Click **Run workflow**
5. Select environment (`dev` or `prod`)
6. Optionally specify an image tag
7. Click **Run workflow**

### 4.2 Automatic Deployment

The workflow supports deployment through:

- **Manual Deployment**: Use workflow dispatch to choose environment (dev/prod)
- **Release Deployment**: Create a release → automatically deploys to `prod`

### 4.3 DNS Configuration

After setup, configure your DNS provider to point to the NGINX Ingress Load Balancer:

```bash
# Get the NGINX Ingress Load Balancer public IP
kubectl get service ingress-nginx-controller \
  --namespace ingress-nginx \
  --output jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Configure these DNS records with your DNS provider:
- `*.homecareapp.xyz  A  <NGINX_LOAD_BALANCER_IP>`
- `homecareapp.xyz    A  <NGINX_LOAD_BALANCER_IP>`

### 4.4 Monitor Deployment

```bash
# Get AKS credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Check deployment status
kubectl get pods -n homecare-dev
kubectl get svc -n homecare-dev
kubectl get ingress -n homecare-dev

# Test application access
curl -H "Host: dev.homecareapp.xyz" http://<NGINX_LOAD_BALANCER_IP>

# Check logs
kubectl logs -f deployment/homecare-app -n homecare-dev
```

## Part 5: Cost Optimization for Free Tier

### 5.1 Resource Limits

The configuration is optimized for Azure free tier with single-node deployment:

- **Base Configuration**: 1 replica, 64Mi memory request, 128Mi limit
- **Dev Environment**: 1 replica, 32Mi memory request, 64Mi limit  
- **Prod Environment**: 1 replica, 64Mi memory request, 128Mi limit
- **Node Size**: Standard_D2plds_v5 (2 vCPUs, 4 GB RAM, ARM-based)
- **Network**: Azure CNI Overlay with Cilium dataplane for efficiency

### 5.2 Cost Estimates

**Monthly Costs (East US)**:
- **AKS Control Plane**: Free (free tier)
- **Standard_D2plds_v5 VM**: ~$60-80/month
- **NGINX Ingress Load Balancer**: ~$5-10/month (Basic Load Balancer)
- **Storage**: ~$5-10/month for managed disks
- **Network**: Minimal for basic setup

**Total Estimated Cost**: ~$70-100/month

### 5.3 Cost Optimization Tips

- Use `scripts/cleanup-aks.sh` to delete resources when not needed
- Monitor Azure Cost Management for usage tracking
- Consider spot instances for non-production workloads
- Standard Azure CNI provides good performance without additional complexity
```

### 5.3 Monitoring Costs

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n homecare-dev
kubectl top pods -n homecare-prod
```

## Part 6: Troubleshooting

### 6.1 Common Issues

**OIDC Authentication Failed**:
- Verify federated identity credentials are configured correctly
- Check that the repository path matches exactly
- Ensure the App ID has proper permissions

**Deployment Failed**:
- Check AKS cluster status: `az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME`
- Verify kubectl context: `kubectl config current-context`
- Check pod logs: `kubectl logs -f deployment/homecare-app -n homecare-dev`

**Resource Limits Exceeded**:
- Monitor resource usage: `kubectl top pods -n homecare-dev`
- Adjust resource limits in the patch files
- Consider scaling down replicas

### 6.2 Useful Commands

```bash
# Get cluster info
kubectl cluster-info

# Check all resources
kubectl get all -n homecare-dev

# Describe problematic pods
kubectl describe pod <pod-name> -n homecare-dev

# Check events
kubectl get events -n homecare-dev --sort-by=.metadata.creationTimestamp

# Scale deployment
kubectl scale deployment/homecare-app --replicas=2 -n homecare-dev
```

## Part 7: Cleanup

To avoid charges, clean up resources when not needed:

```bash
# Delete AKS cluster
az aks delete --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --yes --no-wait

# Delete resource group (removes all resources)
az group delete --name $RESOURCE_GROUP --yes --no-wait

# Delete App Registration
az ad app delete --id $APP_ID
```

## Security Best Practices

1. **Least Privilege**: Only grant necessary permissions to the service principal
2. **Environment Isolation**: Use separate namespaces for dev and prod
3. **Secret Management**: Use Azure Key Vault for sensitive data in production
4. **Network Security**: Implement network policies and ingress controls
5. **Image Security**: Regularly scan container images for vulnerabilities

## Next Steps

1. Set up monitoring with Azure Monitor or Prometheus
2. Implement backup and disaster recovery procedures
3. Configure SSL/TLS certificates for production domains
4. Set up alerting for deployment failures and resource limits
5. Implement blue-green deployments for zero-downtime updates
