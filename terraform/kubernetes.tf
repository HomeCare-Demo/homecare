# AKS Cluster
resource "azurerm_kubernetes_cluster" "homecare" {
  name                = local.cluster_name
  location            = azurerm_resource_group.homecare.location
  resource_group_name = azurerm_resource_group.homecare.name
  dns_prefix          = "${local.prefix}-aks"
  sku_tier            = "Free"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2plds_v5"
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_mode   = "transparent"
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.homecare.id
  }

  tags = local.tags
}
