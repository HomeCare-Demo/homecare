# GitHub repository reference
data "github_repository" "homecare" {
  full_name = "homecare-demo/homecare"
}

# Development environment
resource "github_repository_environment" "dev" {
  repository  = "homecare"
  environment = "dev"
}

# Production environment
resource "github_repository_environment" "prod" {
  repository  = "homecare"
  environment = "prod"
}

# Preview environment for pull request previews
resource "github_repository_environment" "preview" {
  repository  = "homecare"
  environment = "preview"
}

# Repository secrets for Azure authentication
resource "github_actions_secret" "azure_client_id" {
  repository      = "homecare"
  secret_name     = "AZURE_CLIENT_ID"
  plaintext_value = azuread_application.github_actions.client_id
}

resource "github_actions_secret" "azure_tenant_id" {
  repository      = "homecare"
  secret_name     = "AZURE_TENANT_ID"
  plaintext_value = data.azurerm_client_config.current.tenant_id
}

resource "github_actions_secret" "azure_subscription_id" {
  repository      = "homecare"
  secret_name     = "AZURE_SUBSCRIPTION_ID"
  plaintext_value = data.azurerm_client_config.current.subscription_id
}

resource "github_actions_secret" "azure_resource_group" {
  repository      = "homecare"
  secret_name     = "AZURE_RESOURCE_GROUP"
  plaintext_value = azurerm_resource_group.homecare.name
}

resource "github_actions_secret" "azure_cluster_name" {
  repository      = "homecare"
  secret_name     = "AZURE_CLUSTER_NAME"
  plaintext_value = azurerm_kubernetes_cluster.homecare.name
}

# Output GitHub configuration summary
output "github_configuration" {
  description = "GitHub configuration summary"
  value = {
    repository = data.github_repository.homecare.full_name
    environments = [
      github_repository_environment.dev.environment,
      github_repository_environment.prod.environment,
      github_repository_environment.preview.environment
    ]
    secrets_configured = [
      "AZURE_CLIENT_ID",
      "AZURE_TENANT_ID", 
      "AZURE_SUBSCRIPTION_ID",
      "AZURE_RESOURCE_GROUP",
      "AZURE_CLUSTER_NAME"
    ]
    repository_url = data.github_repository.homecare.html_url
  }
}

# Output environment-specific information
output "deployment_environments" {
  description = "Deployment environment configuration"
  value = {
    dev = {
      name = github_repository_environment.dev.environment
    }
    prod = {
      name = github_repository_environment.prod.environment
    }
    preview = {
      name = github_repository_environment.preview.environment
    }
  }
}
