output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.homecare.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.homecare.name
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.appgw.ip_address
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
    application_gateway_ip = azurerm_public_ip.appgw.ip_address
    dns_records = [
      "*.homecareapp.xyz  A  ${azurerm_public_ip.appgw.ip_address}",
      "homecareapp.xyz    A  ${azurerm_public_ip.appgw.ip_address}"
    ]
  }
  
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.homecare.kube_config[0].client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.homecare.kube_config_raw

  sensitive = true
}
