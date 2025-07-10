# Role assignment for Contributor access to resource group
resource "azurerm_role_assignment" "contributor" {
  scope                = azurerm_resource_group.homecare.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Role assignment for Network Contributor access (needed for Application Gateway)
resource "azurerm_role_assignment" "network_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Network Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Role assignment for AKS Cluster User access
resource "azurerm_role_assignment" "aks_cluster_user" {
  scope                = azurerm_kubernetes_cluster.homecare.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azuread_service_principal.github_actions.object_id
}
