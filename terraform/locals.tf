locals {
  # Basic Configuration
  resource_group_name = "homecare"
  location           = "Central India"
  prefix             = "homecare"
  cluster_name       = "homecare"
  app_name          = "homecare-app"
  github_repo       = "mvkaran/homecare"

  # Networking
  vnet_address_space     = ["10.0.0.0/16"]
  appgw_subnet_prefix    = ["10.0.1.0/24"]
  aks_subnet_prefix      = ["10.0.2.0/24"]

  # Application Gateway Configuration
  appgw_capacity = 1
  
  # Tags for all resources
  tags = {
    Project     = "HomeCare"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Owner       = "mvkaran"
  }
}
