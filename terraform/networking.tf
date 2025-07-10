# Virtual Network
resource "azurerm_virtual_network" "homecare" {
  name                = "${local.prefix}-vnet"
  address_space       = local.vnet_address_space
  location            = azurerm_resource_group.homecare.location
  resource_group_name = azurerm_resource_group.homecare.name

  tags = local.tags
}

# Application Gateway Subnet
resource "azurerm_subnet" "appgw" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.homecare.name
  virtual_network_name = azurerm_virtual_network.homecare.name
  address_prefixes     = local.appgw_subnet_prefix
}

# AKS Subnet
resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.homecare.name
  virtual_network_name = azurerm_virtual_network.homecare.name
  address_prefixes     = local.aks_subnet_prefix
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "appgw" {
  name                = "${local.prefix}-pip"
  resource_group_name = azurerm_resource_group.homecare.name
  location            = azurerm_resource_group.homecare.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}
