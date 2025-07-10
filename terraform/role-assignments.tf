# Role assignment for Contributor access to resource group
resource "azurerm_role_assignment" "contributor" {
  scope                = azurerm_resource_group.homecare.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Role assignment for AKS Cluster User access
resource "azurerm_role_assignment" "aks_cluster_user" {
  scope                = azurerm_kubernetes_cluster.homecare.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# AKS Managed Identity Role Assignments
# These are required for the AKS cluster to manage network resources

# Network Contributor role for the AKS managed identity on the resource group
# This allows the cluster to create and manage load balancers and public IPs
resource "azurerm_role_assignment" "aks_network_contributor_rg" {
  scope                = azurerm_resource_group.homecare.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.homecare.identity[0].principal_id
}

# Network Contributor role for the AKS managed identity on the VNet
# This allows the cluster to manage network resources within the VNet
resource "azurerm_role_assignment" "aks_network_contributor_vnet" {
  scope                = azurerm_virtual_network.homecare.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.homecare.identity[0].principal_id
}

# Contributor role for the AKS managed identity on the AKS subnet
# This allows the cluster to join the subnet and manage subnet resources
resource "azurerm_role_assignment" "aks_subnet_contributor" {
  scope                = azurerm_subnet.aks.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.homecare.identity[0].principal_id
}

# Network Contributor role for the AKS managed identity on the managed resource group
# This is required for the cluster to manage resources in the MC_ resource group
resource "azurerm_role_assignment" "aks_mc_network_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_kubernetes_cluster.homecare.node_resource_group}"
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.homecare.identity[0].principal_id
  
  depends_on = [azurerm_kubernetes_cluster.homecare]
}
