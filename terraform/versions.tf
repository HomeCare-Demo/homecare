terraform {
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
  }
}
