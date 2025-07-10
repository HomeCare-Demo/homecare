#!/bin/bash

# Azure AKS Setup Script for HomeCare Application
# This script helps set up the required Azure resources and OIDC configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RESOURCE_GROUP="homecare-rg"
LOCATION="eastus"
CLUSTER_NAME="homecare-aks"
APP_NAME="homecare-app"
APPGW_NAME="homecare-appgw"
APPGW_SUBNET_NAME="appgw-subnet"
VNET_NAME="homecare-vnet"
PIP_NAME="homecare-pip"
GITHUB_REPO=""
APPGW_PUBLIC_IP=""

# Functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if Azure CLI is installed
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        error "Azure CLI is not installed. Please install it first: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    fi
}

# Check if user is logged in
check_azure_login() {
    if ! az account show &> /dev/null; then
        error "Not logged in to Azure. Please run: az login"
    fi
}

# Get user input
get_user_input() {
    echo -e "${BLUE}=== HomeCare AKS Setup Configuration ===${NC}"
    echo
    
    read -p "Resource Group Name [$RESOURCE_GROUP]: " input_rg
    RESOURCE_GROUP=${input_rg:-$RESOURCE_GROUP}
    
    read -p "Azure Location [$LOCATION]: " input_location
    LOCATION=${input_location:-$LOCATION}
    
    read -p "AKS Cluster Name [$CLUSTER_NAME]: " input_cluster
    CLUSTER_NAME=${input_cluster:-$CLUSTER_NAME}
    
    read -p "Application Gateway Name [$APPGW_NAME]: " input_appgw
    APPGW_NAME=${input_appgw:-$APPGW_NAME}
    
    read -p "GitHub Repository (format: username/repo): " input_repo
    if [ -z "$input_repo" ]; then
        error "GitHub repository is required"
    fi
    GITHUB_REPO=$input_repo
    
    echo
    echo -e "${BLUE}Configuration Summary:${NC}"
    echo "Resource Group: $RESOURCE_GROUP"
    echo "Location: $LOCATION"
    echo "Cluster Name: $CLUSTER_NAME"
    echo "Application Gateway: $APPGW_NAME"
    echo "GitHub Repo: $GITHUB_REPO"
    echo
    
    read -p "Continue with this configuration? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "Setup cancelled by user"
        exit 0
    fi
}

# Create resource group
create_resource_group() {
    if az group exists --name "$RESOURCE_GROUP" &> /dev/null; then
        log "Resource group '$RESOURCE_GROUP' already exists, skipping creation"
    else
        log "Creating resource group: $RESOURCE_GROUP"
        az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    fi
}

# Create AKS cluster
create_aks_cluster() {
    if az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" &> /dev/null; then
        log "AKS cluster '$CLUSTER_NAME' already exists, skipping creation"
    else
        log "Creating AKS cluster: $CLUSTER_NAME (this may take 10-15 minutes)"
        az aks create \
            --resource-group "$RESOURCE_GROUP" \
            --name "$CLUSTER_NAME" \
            --node-count 1 \
            --node-vm-size Standard_D2plds_v5 \
            --enable-managed-identity \
            --generate-ssh-keys \
            --tier free \
            --network-plugin azure \
            --network-plugin-mode overlay \
            --yes
    fi
}

# Create Application Gateway and configure AGIC
setup_application_gateway() {
    log "Setting up Application Gateway and AGIC"
    
    # Always ensure networking infrastructure exists
    log "Checking networking infrastructure for Application Gateway"
    
    # Create virtual network if it doesn't exist
    if ! az network vnet show --resource-group "$RESOURCE_GROUP" --name "$VNET_NAME" &> /dev/null; then
        log "Creating virtual network: $VNET_NAME"
        az network vnet create \
            --resource-group "$RESOURCE_GROUP" \
            --name "$VNET_NAME" \
            --location "$LOCATION" \
            --address-prefixes 10.0.0.0/16
    else
        log "Virtual network '$VNET_NAME' already exists"
    fi
    
    # Create subnet for Application Gateway if it doesn't exist
    if ! az network vnet subnet show --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --name "$APPGW_SUBNET_NAME" &> /dev/null; then
        log "Creating Application Gateway subnet: $APPGW_SUBNET_NAME"
        az network vnet subnet create \
            --resource-group "$RESOURCE_GROUP" \
            --vnet-name "$VNET_NAME" \
            --name "$APPGW_SUBNET_NAME" \
            --address-prefixes 10.0.1.0/24
    else
        log "Application Gateway subnet '$APPGW_SUBNET_NAME' already exists"
    fi
    
    # Create public IP for Application Gateway if it doesn't exist
    if ! az network public-ip show --resource-group "$RESOURCE_GROUP" --name "$PIP_NAME" &> /dev/null; then
        log "Creating public IP for Application Gateway: $PIP_NAME"
        az network public-ip create \
            --resource-group "$RESOURCE_GROUP" \
            --name "$PIP_NAME" \
            --location "$LOCATION" \
            --allocation-method Static \
            --sku Standard
    else
        log "Public IP '$PIP_NAME' already exists"
    fi
    
    # Check if Application Gateway already exists
    if az network application-gateway show --resource-group "$RESOURCE_GROUP" --name "$APPGW_NAME" &> /dev/null; then
        log "Application Gateway '$APPGW_NAME' already exists"
    else
        log "Creating Application Gateway: $APPGW_NAME (this may take 5-10 minutes)"
        az network application-gateway create \
            --resource-group "$RESOURCE_GROUP" \
            --name "$APPGW_NAME" \
            --location "$LOCATION" \
            --capacity 2 \
            --sku Standard_v2 \
            --vnet-name "$VNET_NAME" \
            --subnet "$APPGW_SUBNET_NAME" \
            --public-ip-address "$PIP_NAME" \
            --http-settings-cookie-based-affinity Disabled \
            --http-settings-port 80 \
            --http-settings-protocol Http \
            --frontend-port 80
    fi
    
    # Check if AGIC addon is enabled
    AGIC_ENABLED=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query "addonProfiles.ingressApplicationGateway.enabled" --output tsv 2>/dev/null || echo "false")
    
    if [ "$AGIC_ENABLED" = "true" ]; then
        log "AGIC addon is already enabled on AKS cluster"
    else
        log "Enabling AGIC addon on AKS cluster"
        az aks enable-addons \
            --resource-group "$RESOURCE_GROUP" \
            --name "$CLUSTER_NAME" \
            --addons ingress-appgw \
            --appgw-name "$APPGW_NAME"
    fi
    
    # Get and display the Application Gateway public IP
    APPGW_PUBLIC_IP=$(az network public-ip show --resource-group "$RESOURCE_GROUP" --name "$PIP_NAME" --query ipAddress --output tsv)
    log "Application Gateway Public IP: $APPGW_PUBLIC_IP"
}

# Create app registration and service principal
create_app_registration() {
    log "Creating or checking Azure AD app registration"
    
    # Check if app already exists
    EXISTING_APP=$(az ad app list --display-name "$APP_NAME-github-actions" --query "[0].appId" --output tsv 2>/dev/null || echo "")
    
    if [ -n "$EXISTING_APP" ] && [ "$EXISTING_APP" != "null" ]; then
        log "App registration '$APP_NAME-github-actions' already exists"
        APP_ID="$EXISTING_APP"
        
        # Check if service principal exists
        if az ad sp show --id "$APP_ID" &> /dev/null; then
            log "Service principal for app already exists"
        else
            log "Creating service principal for existing app"
            az ad sp create --id "$APP_ID"
        fi
    else
        log "Creating new app registration"
        APP_ID=$(az ad app create --display-name "$APP_NAME-github-actions" --query appId --output tsv)
        
        # Create service principal
        log "Creating service principal"
        az ad sp create --id "$APP_ID"
    fi
    
    log "App ID: $APP_ID"
    
    # Get IDs
    TENANT_ID=$(az account show --query tenantId --output tsv)
    SUBSCRIPTION_ID=$(az account show --query id --output tsv)
    
    log "Tenant ID: $TENANT_ID"
    log "Subscription ID: $SUBSCRIPTION_ID"
    
    # Store in variables file
    cat > azure-config.env << EOF
AZURE_CLIENT_ID=$APP_ID
AZURE_TENANT_ID=$TENANT_ID
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP
AZURE_CLUSTER_NAME=$CLUSTER_NAME
EOF
    
    log "Azure configuration saved to azure-config.env"
}

# Assign permissions
assign_permissions() {
    log "Checking and assigning permissions to service principal"
    
    # Check and assign Contributor role to the resource group
    RG_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
    EXISTING_CONTRIBUTOR=$(az role assignment list --assignee "$APP_ID" --scope "$RG_SCOPE" --role "Contributor" --query "length([?roleDefinitionName=='Contributor'])" --output tsv 2>/dev/null || echo "0")
    
    if [ "$EXISTING_CONTRIBUTOR" != "0" ]; then
        log "Contributor role already assigned to resource group"
    else
        log "Assigning Contributor role to resource group"
        az role assignment create \
            --role Contributor \
            --assignee "$APP_ID" \
            --scope "$RG_SCOPE"
    fi
    
    # Check and assign AKS Cluster User role
    AKS_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME"
    EXISTING_AKS_USER=$(az role assignment list --assignee "$APP_ID" --scope "$AKS_SCOPE" --role "Azure Kubernetes Service Cluster User Role" --query "length([?roleDefinitionName=='Azure Kubernetes Service Cluster User Role'])" --output tsv 2>/dev/null || echo "0")
    
    if [ "$EXISTING_AKS_USER" != "0" ]; then
        log "AKS Cluster User role already assigned"
    else
        log "Assigning AKS Cluster User role"
        az role assignment create \
            --role "Azure Kubernetes Service Cluster User Role" \
            --assignee "$APP_ID" \
            --scope "$AKS_SCOPE"
    fi
}

# Configure federated identity credentials
configure_federated_identity() {
    log "Configuring federated identity credentials"
    
    # Helper function to check if federated credential exists
    check_federated_credential() {
        local name="$1"
        az ad app federated-credential list --id "$APP_ID" --query "[?name=='$name']" --output tsv 2>/dev/null | grep -q "$name"
    }
    
    # For main branch deployments
    if check_federated_credential "homecare-main-branch"; then
        log "Federated credential 'homecare-main-branch' already exists"
    else
        log "Creating federated credential for main branch"
        az ad app federated-credential create \
            --id "$APP_ID" \
            --parameters "{
                \"name\": \"homecare-main-branch\",
                \"issuer\": \"https://token.actions.githubusercontent.com\",
                \"subject\": \"repo:$GITHUB_REPO:ref:refs/heads/main\",
                \"description\": \"Main branch deployment\",
                \"audiences\": [\"api://AzureADTokenExchange\"]
            }"
    fi
    
    # For release deployments
    if check_federated_credential "homecare-releases"; then
        log "Federated credential 'homecare-releases' already exists"
    else
        log "Creating federated credential for releases"
        az ad app federated-credential create \
            --id "$APP_ID" \
            --parameters "{
                \"name\": \"homecare-releases\",
                \"issuer\": \"https://token.actions.githubusercontent.com\",
                \"subject\": \"repo:$GITHUB_REPO:ref:refs/tags/*\",
                \"description\": \"Release deployment\",
                \"audiences\": [\"api://AzureADTokenExchange\"]
            }"
    fi
    
    # For workflow dispatch
    if check_federated_credential "homecare-workflow-dispatch"; then
        log "Federated credential 'homecare-workflow-dispatch' already exists"
    else
        log "Creating federated credential for workflow dispatch"
        az ad app federated-credential create \
            --id "$APP_ID" \
            --parameters "{
                \"name\": \"homecare-workflow-dispatch\",
                \"issuer\": \"https://token.actions.githubusercontent.com\",
                \"subject\": \"repo:$GITHUB_REPO:ref:refs/heads/main\",
                \"description\": \"Manual workflow dispatch\",
                \"audiences\": [\"api://AzureADTokenExchange\"]
            }"
    fi
    
    # For any branch deployments
    if check_federated_credential "homecare-branches"; then
        log "Federated credential 'homecare-branches' already exists"
    else
        log "Creating federated credential for all branches"
        az ad app federated-credential create \
            --id "$APP_ID" \
            --parameters "{
                \"name\": \"homecare-branches\",
                \"issuer\": \"https://token.actions.githubusercontent.com\",
                \"subject\": \"repo:$GITHUB_REPO:ref:refs/heads/*\",
                \"description\": \"All branch deployments\",
                \"audiences\": [\"api://AzureADTokenExchange\"]
            }"
    fi
}

# Print next steps
print_next_steps() {
    echo
    echo -e "${GREEN}=== Setup Complete! ===${NC}"
    echo
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Add the following secrets to your GitHub repository:"
    echo "   Settings → Secrets and variables → Actions"
    echo
    echo "   Repository secrets:"
    echo "   - AZURE_CLIENT_ID: $APP_ID"
    echo "   - AZURE_TENANT_ID: $TENANT_ID"
    echo "   - AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
    echo "   - AZURE_RESOURCE_GROUP: $RESOURCE_GROUP"
    echo "   - AZURE_CLUSTER_NAME: $CLUSTER_NAME"
    echo
    echo "2. Create GitHub environments:"
    echo "   - dev (for development deployments)"
    echo "   - prod (for production deployments)"
    echo
    echo "3. Configure DNS for your domain:"
    echo "   Point your DNS records to Application Gateway IP: $APPGW_PUBLIC_IP"
    echo "   - *.homecareapp.xyz  A  $APPGW_PUBLIC_IP"
    echo "   - homecareapp.xyz    A  $APPGW_PUBLIC_IP"
    echo
    echo "4. Test the deployment:"
    echo "   - Go to Actions tab in your GitHub repository"
    echo "   - Run 'Deploy to AKS' workflow manually"
    echo
    echo -e "${YELLOW}Configuration saved to: azure-config.env${NC}"
    echo -e "${YELLOW}Keep this file secure and do not commit it to version control${NC}"
}

# Main execution
main() {
    log "Starting HomeCare AKS Setup"
    
    check_azure_cli
    check_azure_login
    get_user_input
    
    create_resource_group
    create_aks_cluster
    setup_application_gateway
    create_app_registration
    assign_permissions
    configure_federated_identity
    
    print_next_steps
    
    log "Setup completed successfully!"
}

# Run main function
main "$@"
