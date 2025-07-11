# Quick Setup Checklist

## Manual Inputs Required

### 1. Azure Configuration
- [ ] **Resource Group Name**: `homecare-rg` (or your preferred name)
- [ ] **AKS Cluster Name**: `homecare-aks` (or your preferred name)
- [ ] **Azure Location**: `eastus` (or your preferred region)
- [ ] **GitHub Repository**: `YOUR_GITHUB_USERNAME/homecare` (replace with actual)

### 2. GitHub Secrets to Configure
Navigate to **Settings** → **Secrets and variables** → **Actions** and add:

- [ ] `AZURE_CLIENT_ID` - From Azure AD app registration
- [ ] `AZURE_TENANT_ID` - From Azure account
- [ ] `AZURE_SUBSCRIPTION_ID` - From Azure account
- [ ] `AZURE_RESOURCE_GROUP` - Resource group name
- [ ] `AZURE_CLUSTER_NAME` - AKS cluster name

### 3. Domain Configuration
The ingress is already configured for your domain:

- ✅ **Production**: `homecareapp.xyz`
- ✅ **Development**: `dev.homecareapp.xyz`

### 4. DNS Configuration
Configure wildcard DNS at your DNS provider:
- [ ] `*.homecareapp.xyz  A  <NGINX_LOAD_BALANCER_IP>`
- [ ] `homecareapp.xyz    A  <NGINX_LOAD_BALANCER_IP>`

(The setup script will provide the actual IP address)

## Automated Setup (Recommended)

Use the provided Terraform configuration and NGINX scripts for automated setup:

```bash
# Initialize and deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# Install NGINX Ingress Controller
./scripts/install-nginx-ingress.sh
```

The setup process will:
- Create all Azure resources (RG, AKS) using Terraform
- Install NGINX Ingress Controller
- Require manual OIDC setup with GitHub Actions
- Generate all required configuration values
- Provide DNS configuration instructions

## Manual Setup (Alternative)

If you prefer manual setup, use these variables:

```bash
RESOURCE_GROUP="homecare-rg"              # Your resource group name
LOCATION="eastus"                         # Your preferred Azure region
CLUSTER_NAME="homecare-aks"               # Your AKS cluster name
APP_NAME="homecare-app"                   # Application name
```

## GitHub Repository Settings

### Environments
Create these environments in GitHub:
- [ ] `dev` - Development environment
- [ ] `prod` - Production environment

### Branch Protection (Optional)
- [ ] Protect `main` branch
- [ ] Require pull request reviews for production deployments

## Deployment Options

### Manual Deployment
- Environment: `dev` or `prod`
- Image tag: Leave blank for auto-generated tag

### Automatic Deployment
- **Manual Trigger**: Workflow dispatch (choose environment)
- **Release Trigger**: Create release → deploys to `prod`

## Resource Limits Summary

| Environment | Replicas | Memory Request | Memory Limit | CPU Request | CPU Limit |
|-------------|----------|----------------|--------------|-------------|-----------|
| Base        | 1        | 64Mi           | 128Mi        | 50m         | 100m      |
| Dev         | 1        | 32Mi           | 64Mi         | 25m         | 50m       |
| Prod        | 1        | 64Mi           | 128Mi        | 50m         | 100m      |

**Note**: All environments now use 1 replica for cost optimization on single-node AKS.

## Post-Deployment Verification

Check these after deployment:

```bash
# 1. Check pods are running
kubectl get pods -n homecare-dev

# 2. Check service is accessible
kubectl get svc -n homecare-dev

# 4. Check ingress and get external IP
kubectl get ingress -n homecare-dev

# 5. Test application access
curl -H "Host: dev.homecareapp.xyz" http://<NGINX_LOAD_BALANCER_IP>

# 6. Check application logs
kubectl logs -f deployment/homecare-app -n homecare-dev
```

## Estimated Costs (Free Tier)

- **AKS Cluster**: Free (with 1 Standard_D2plds_v5 ARM64 node)
- **Compute**: ~$60-80/month for Standard_D2plds_v5 VM (ARM64-based)
- **Storage**: ~$5-10/month for managed disks
- **Networking**: Minimal for basic setup

**Note**: ARM64-based VMs provide better price/performance ratio. Monitor usage to stay within free tier limits and avoid unexpected charges.
