terraform {
  required_version = ">= 1.9.0"
  
  cloud {
    organization = "mvkaran"

    workspaces {
      name = "homecare"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.35"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.4"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}
