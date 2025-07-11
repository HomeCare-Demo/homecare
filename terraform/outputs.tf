output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.homecare.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.homecare.name
}

output "cluster_info" {
  description = "AKS cluster information"
  value = {
    cluster_name = azurerm_kubernetes_cluster.homecare.name
    resource_group = azurerm_resource_group.homecare.name
    location = azurerm_resource_group.homecare.location
  }
}

output "azure_client_id" {
  description = "Client ID for GitHub Actions OIDC"
  value       = azuread_application.github_actions.client_id
  sensitive   = true
}

output "azure_tenant_id" {
  description = "Azure Tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
  sensitive   = true
}

output "azure_subscription_id" {
  description = "Azure Subscription ID"
  value       = data.azurerm_client_config.current.subscription_id
  sensitive   = true
}

output "github_secrets_summary" {
  description = "Summary of required GitHub secrets"
  value = {
    AZURE_CLIENT_ID       = azuread_application.github_actions.client_id
    AZURE_TENANT_ID       = data.azurerm_client_config.current.tenant_id
    AZURE_SUBSCRIPTION_ID = data.azurerm_client_config.current.subscription_id
    AZURE_RESOURCE_GROUP  = azurerm_resource_group.homecare.name
    AZURE_CLUSTER_NAME    = azurerm_kubernetes_cluster.homecare.name
  }
  sensitive = true
}

output "dns_configuration" {
  description = "DNS configuration instructions"
  value = {
    instructions = "After installing NGINX Ingress Controller, get the external IP with: kubectl get svc -n ingress-nginx ingress-nginx-controller"
    dns_records_template = [
      "*.homecareapp.xyz  A  <NGINX_INGRESS_IP>",
      "homecareapp.xyz    A  <NGINX_INGRESS_IP>"
    ]
    note = "Replace <NGINX_INGRESS_IP> with the actual LoadBalancer IP from the NGINX Ingress service"
  }
}

# Kubernetes configuration outputs removed to avoid connectivity issues
# Use 'az aks get-credentials' command instead to configure kubectl

output "kubectl_config_command" {
  description = "Command to configure kubectl for this AKS cluster"
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.homecare.name} --name ${azurerm_kubernetes_cluster.homecare.name}"
}

output "github_configuration_summary" {
  description = "GitHub repository configuration summary"
  value = {
    repository_url = "https://github.com/mvkaran/homecare"
    environments_created = ["dev", "prod"]
    secrets_configured = [
      "AZURE_CLIENT_ID",
      "AZURE_TENANT_ID", 
      "AZURE_SUBSCRIPTION_ID",
      "AZURE_RESOURCE_GROUP",
      "AZURE_CLUSTER_NAME"
    ]
    workflow_file = ".github/workflows/deploy.yml"
    deployment_notes = [
      "Development environment: Allows custom branch deployments",
      "Production environment: Only protected branches allowed",
      "Manual deployments available via GitHub Actions workflow_dispatch",
      "Automatic production deployment on GitHub releases"
    ]
  }
}

output "deployment_instructions" {
  description = "Instructions for deploying the application"
  value = {
    manual_deployment = "Go to Actions tab → Deploy to AKS → Run workflow"
    release_deployment = "Create a GitHub release to automatically deploy to production"
    dev_url_template = "https://dev.homecareapp.xyz (after DNS configuration)"
    prod_url_template = "https://homecareapp.xyz (after DNS configuration)"
    monitoring = "Check deployment status in GitHub Actions and AKS pod logs"
  }
}
