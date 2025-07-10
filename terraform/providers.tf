# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  client_id = var.appId
  client_secret = var.password
  tenant_id = var.tenantId
  subscription_id = var.subscriptionId
  
  # Use environment variables for authentication in Terraform Cloud
  # Set these in your Terraform Cloud workspace:
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID
}

# Configure the Azure Active Directory Provider  
provider "azuread" {
  # Uses the same environment variables as azurerm provider
  client_id = var.appId
  client_secret = var.password
  tenant_id = var.tenantId
}
