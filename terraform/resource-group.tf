# Resource Group
resource "azurerm_resource_group" "homecare" {
  name     = local.resource_group_name
  location = local.location

  tags = local.tags
}
