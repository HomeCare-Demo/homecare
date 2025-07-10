locals {
  # Basic Configuration
  resource_group_name = "homecare-app"
  location           = "Central India"
  prefix             = "homecare-app"
  cluster_name       = "homecare-app"
  app_name          = "homecare-app"
  github_repo       = "mvkaran/homecare"

  # Networking
  vnet_address_space     = ["10.0.0.0/16"]
  aks_subnet_prefix      = ["10.0.2.0/24"]
  
  # Tags for all resources
  tags = {
    Project     = "HomeCare"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Owner       = "mvkaran"
  }
}
