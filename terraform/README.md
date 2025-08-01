# HomeCare Infrastructure with Terraform

This directory contains Terraform configuration files to provision the complete Azure infrastructure for the HomeCare application. The configuration is organized into focused, single-responsibility files for maximum readability and maintainability.

## Configuration Files Overview

- **versions.tf**: Terraform version constraints and required provider definitions
- **providers.tf**: Azure and Azure AD provider configurations
- **data.tf**: External data sources and references
- **locals.tf**: Local values, variables, and configuration settings
- **resource-group.tf**: Azure Resource Group definition
- **networking.tf**: Virtual networks, subnets, and public IP resources
- **application-gateway.tf**: Application Gateway configuration for load balancing
- **kubernetes.tf**: Azure Kubernetes Service (AKS) cluster setup
- **azure-ad.tf**: Azure Active Directory application and service principal
- **role-assignments.tf**: RBAC role assignments for service principal
- **federated-identity.tf**: GitHub Actions OIDC identity federation setup
- **github.tf**: GitHub repository configuration, environments, and secrets management
- **outputs.tf**: Output values for use in other configurations or CI/CD

## What gets created

### Azure Resources
- **Resource Group**: Contains all resources
- **Virtual Network**: With subnets for Application Gateway and AKS
- **Application Gateway**: Standard Small tier (most cost-effective available in Terraform)
- **AKS Cluster**: Single-node cluster optimized for free tier
- **Azure AD App Registration**: For GitHub Actions OIDC authentication
- **Service Principal**: With appropriate role assignments
- **Federated Identity Credentials**: For secure GitHub Actions deployment

### GitHub Configuration
- **Repository Environments**: `dev` and `prod` environments with protection rules
- **Repository Secrets**: Azure credentials for OIDC authentication
- **Branch Protection**: Main branch protection with PR reviews and status checks
- **Repository Settings**: Security settings, topics, and merge policies

## Prerequisites

1. **Azure CLI**: Installed and authenticated (`az login`)
2. **Terraform**: Installed locally or use Terraform Cloud
3. **Terraform Cloud Account**: For remote state management
4. **GitHub Repository**: Fork of homecare-demo/homecare
5. **GitHub Personal Access Token**: With `repo`, `admin:repo_hook`, and `admin:org` permissions

## Setup Instructions

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Configure Azure Authentication

Since you're using Terraform Cloud, you need to set up Azure service principal authentication:

1. **Create a Service Principal** (one-time setup):
   ```bash
   # Login to Azure
   az login
   
   # Create service principal
   az ad sp create-for-rbac --name "terraform-homecare" --role Contributor --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
   ```

2. **Add Environment Variables in Terraform Cloud**:
   - Go to: https://app.terraform.io/app/homecare-demo/workspaces/homecare
   - Navigate to **Variables** tab
   - Add these **Environment Variables** (marked as sensitive):
     - `ARM_CLIENT_ID` = Application (client) ID from service principal
     - `ARM_CLIENT_SECRET` = Client secret value from service principal  
     - `ARM_SUBSCRIPTION_ID` = Your Azure subscription ID
     - `ARM_TENANT_ID` = Your Azure tenant ID

### 3. Configure Settings (Optional)

All configuration is pre-set using locals in `locals.tf`. The default values are:

- **Resource Group**: `homecare`
- **Location**: `Central India`  
- **GitHub Repository**: `homecare-demo/homecare`
- **Cluster Name**: `homecare`

If you need to customize any values, edit the `locals.tf` file before deployment.

### 4. Plan and Apply

```bash
# Review the planned changes
terraform plan

# Apply the changes
terraform apply
```

### 5. Get Output Values

After successful deployment:

```bash
# Get all outputs
terraform output

# Get specific sensitive outputs
terraform output -raw azure_client_id
terraform output -raw azure_tenant_id
terraform output -raw azure_subscription_id

# Get GitHub secrets summary
terraform output github_secrets_summary
```

### 6. Configure GitHub Secrets

Add these secrets to your GitHub repository (**Settings** → **Secrets and variables** → **Actions**):

- `AZURE_CLIENT_ID`: From terraform output
- `AZURE_TENANT_ID`: From terraform output  
- `AZURE_SUBSCRIPTION_ID`: From terraform output
- `AZURE_RESOURCE_GROUP`: From terraform output
- `AZURE_CLUSTER_NAME`: From terraform output

### 7. Configure DNS

Point your domain DNS records to the Application Gateway IP:

```bash
# Get the Application Gateway IP
terraform output application_gateway_public_ip
```

Configure these DNS A records:
- `*.homecareapp.xyz` → Application Gateway IP
- `homecareapp.xyz` → Application Gateway IP

## Terraform Cloud Configuration

This configuration uses Terraform Cloud for remote state management:

- **Organization**: homecare-demo
- **Workspace**: homecare

The remote state configuration is already set up in `main.tf`.

## Cost Optimization

The infrastructure is optimized for cost:

- **Application Gateway**: Standard Small tier (smallest available in Terraform)
- **AKS**: Free tier with single Standard_D2plds_v5 node (ARM64-based)
- **Networking**: Minimal configuration
- **Storage**: Standard managed disks

**Estimated monthly cost**: ~$75-100 USD

## Management Commands

```bash
# View current state
terraform show

# Update infrastructure
terraform plan
terraform apply

# Destroy infrastructure (when no longer needed)
terraform destroy

# Format configuration files
terraform fmt

# Validate configuration
terraform validate
```

## Troubleshooting

### Common Issues

1. **Authentication Error**: Ensure your Terraform Cloud workspace has the correct Azure environment variables (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID)
2. **Permission Errors**: Verify your service principal has sufficient permissions (Contributor role)
3. **Resource Conflicts**: Check if resources already exist with the same names
4. **Service Principal Creation**: Ensure you have permission to create service principals in your Azure AD

### Getting Help

1. Check Terraform plan output for detailed error messages
2. Review Azure portal for resource creation status
3. Check Terraform Cloud workspace for execution logs
4. Verify variable values in `terraform.tfvars`

## File Structure

```
terraform/
├── versions.tf              # Terraform version and required providers
├── providers.tf            # Provider configurations (Azure, Azure AD)
├── data.tf                 # Data sources and external references
├── locals.tf               # Local values and configuration
├── resource-group.tf       # Azure Resource Group
├── networking.tf           # Virtual Network, Subnets, Public IP
├── application-gateway.tf  # Application Gateway configuration
├── kubernetes.tf           # AKS Cluster configuration
├── azure-ad.tf             # Azure AD Application and Service Principal
├── role-assignments.tf     # Azure RBAC role assignments
├── federated-identity.tf   # GitHub Actions OIDC credentials
├── github.tf                # GitHub repository configuration
├── outputs.tf              # Output definitions
├── terraform.tfvars.example # Example variables (reference only)
└── README.md               # This file
```

## Security Best Practices

1. **Never commit** `terraform.tfvars` with sensitive values
2. **Use Terraform Cloud** for remote state and variable management
3. **Rotate credentials** regularly
4. **Follow least privilege** principle for role assignments
5. **Enable Azure Security Center** recommendations

## Next Steps

After infrastructure deployment:

1. **Test AKS connection**: `az aks get-credentials --resource-group homecare --name homecare`
2. **Run GitHub Actions**: Deploy your application using the CI/CD pipeline
3. **Monitor resources**: Set up Azure Monitor and alerts
4. **Configure backup**: Implement backup strategies for critical data
5. **Security hardening**: Review and implement additional security measures
