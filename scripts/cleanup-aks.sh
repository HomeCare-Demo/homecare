#!/bin/bash

# Azure AKS Cleanup Script for HomeCare Application
# This script helps clean up Azure resources to avoid charges

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Load configuration
load_config() {
    if [ -f "azure-config.env" ]; then
        source azure-config.env
        log "Loaded configuration from azure-config.env"
    else
        warn "azure-config.env not found. You'll need to provide resource names manually."
    fi
}

# Get user input
get_user_input() {
    echo -e "${BLUE}=== HomeCare AKS Cleanup ===${NC}"
    echo
    
    if [ -z "$AZURE_RESOURCE_GROUP" ]; then
        read -p "Resource Group Name: " AZURE_RESOURCE_GROUP
    else
        read -p "Resource Group Name [$AZURE_RESOURCE_GROUP]: " input_rg
        AZURE_RESOURCE_GROUP=${input_rg:-$AZURE_RESOURCE_GROUP}
    fi
    
    if [ -z "$AZURE_CLIENT_ID" ]; then
        read -p "App Registration ID (optional): " AZURE_CLIENT_ID
    else
        read -p "App Registration ID [$AZURE_CLIENT_ID]: " input_app_id
        AZURE_CLIENT_ID=${input_app_id:-$AZURE_CLIENT_ID}
    fi
    
    echo
    echo -e "${BLUE}Resources to be deleted:${NC}"
    echo "Resource Group: $AZURE_RESOURCE_GROUP (and all resources within)"
    if [ -n "$AZURE_CLIENT_ID" ]; then
        echo "App Registration: $AZURE_CLIENT_ID"
    fi
    echo
    
    echo -e "${RED}WARNING: This action cannot be undone!${NC}"
    echo -e "${RED}All resources in the resource group will be permanently deleted.${NC}"
    echo
    
    read -p "Are you sure you want to continue? Type 'DELETE' to confirm: " confirm
    if [[ "$confirm" != "DELETE" ]]; then
        log "Cleanup cancelled by user"
        exit 0
    fi
}

# List resources in the resource group
list_resources() {
    log "Checking if resource group exists: $AZURE_RESOURCE_GROUP"
    
    if az group exists --name "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        log "Resource group found. Listing resources..."
        echo -e "${BLUE}Resources that will be deleted:${NC}"
        az resource list --resource-group "$AZURE_RESOURCE_GROUP" --output table
        echo
        
        # Check for AGIC addon and warn user
        if az aks show --resource-group "$AZURE_RESOURCE_GROUP" --query "addonProfiles.ingressApplicationGateway.enabled" --output tsv 2>/dev/null | grep -q "true"; then
            echo -e "${YELLOW}WARNING: AGIC addon is enabled on the AKS cluster.${NC}"
            echo -e "${YELLOW}This will also remove the Application Gateway and all its configurations.${NC}"
            echo
        fi
        
        read -p "Proceed with deletion? (y/N): " final_confirm
        if [[ ! $final_confirm =~ ^[Yy]$ ]]; then
            log "Cleanup cancelled by user"
            exit 0
        fi
        return 0
    else
        warn "Resource group $AZURE_RESOURCE_GROUP does not exist"
        return 1
    fi
}

# Delete resource group
delete_resource_group() {
    if az group exists --name "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        log "Deleting resource group: $AZURE_RESOURCE_GROUP"
        log "This may take several minutes..."
        
        az group delete --name "$AZURE_RESOURCE_GROUP" --yes --no-wait
        
        log "Resource group deletion initiated (running in background)"
    else
        warn "Resource group $AZURE_RESOURCE_GROUP does not exist, skipping deletion"
    fi
}

# Delete app registration
delete_app_registration() {
    if [ -n "$AZURE_CLIENT_ID" ]; then
        log "Deleting App Registration: $AZURE_CLIENT_ID"
        
        if az ad app show --id "$AZURE_CLIENT_ID" &> /dev/null; then
            az ad app delete --id "$AZURE_CLIENT_ID"
            log "App registration deleted successfully"
        else
            warn "App registration $AZURE_CLIENT_ID not found"
        fi
    else
        warn "No App Registration ID provided, skipping deletion"
    fi
}

# Print cleanup status
print_cleanup_status() {
    echo
    echo -e "${GREEN}=== Cleanup Initiated ===${NC}"
    echo
    echo -e "${BLUE}Status:${NC}"
    echo "✓ Resource group deletion started (running in background)"
    echo "✓ This includes AKS cluster, Application Gateway, VNet, and all related resources"
    if [ -n "$AZURE_CLIENT_ID" ]; then
        echo "✓ App registration deleted"
    fi
    echo
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Monitor the deletion progress in Azure Portal"
    echo "2. Update your DNS records to remove the Application Gateway IP"
    echo "3. Remove GitHub repository secrets:"
    echo "3. Remove GitHub repository secrets:"
    echo "   - AZURE_CLIENT_ID"
    echo "   - AZURE_TENANT_ID"
    echo "   - AZURE_SUBSCRIPTION_ID"
    echo "   - AZURE_RESOURCE_GROUP"
    echo "   - AZURE_CLUSTER_NAME"
    echo
    echo "4. Clean up local files:"
    echo "   - rm azure-config.env"
    echo
    echo -e "${YELLOW}Note: Resource group deletion may take 10-15 minutes to complete${NC}"
    echo -e "${YELLOW}You can check the status in the Azure Portal${NC}"
}

# Main execution
main() {
    log "Starting HomeCare AKS Cleanup"
    
    check_azure_cli
    check_azure_login
    load_config
    get_user_input
    
    if list_resources; then
        delete_resource_group
        delete_app_registration
        print_cleanup_status
    else
        log "No resources to clean up"
    fi
    
    log "Cleanup process completed!"
}

# Run main function
main "$@"
