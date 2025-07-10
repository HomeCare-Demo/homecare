# Virtual Network
resource "azurerm_virtual_network" "homecare" {
  name                = "${local.prefix}-vnet"
  address_space       = local.vnet_address_space
  location            = azurerm_resource_group.homecare.location
  resource_group_name = azurerm_resource_group.homecare.name

  tags = local.tags
}

# AKS Subnet
resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.homecare.name
  virtual_network_name = azurerm_virtual_network.homecare.name
  address_prefixes     = local.aks_subnet_prefix
}
