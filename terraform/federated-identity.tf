# Federated Identity Credentials for GitHub Actions OIDC

# Main branch deployments
resource "azuread_application_federated_identity_credential" "main_branch" {
  application_id = azuread_application.github_actions.id
  display_name   = "homecare-main-branch"
  description    = "Main branch deployment"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.github_repo}:ref:refs/heads/main"
}

# Release deployments
resource "azuread_application_federated_identity_credential" "releases" {
  application_id = azuread_application.github_actions.id
  display_name   = "homecare-releases"
  description    = "Release deployment"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.github_repo}:ref:refs/tags/*"
}

# Manual workflow dispatch
resource "azuread_application_federated_identity_credential" "workflow_dispatch" {
  application_id = azuread_application.github_actions.id
  display_name   = "homecare-workflow-dispatch"
  description    = "Manual workflow dispatch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.github_repo}:ref:refs/heads/main"
}

# All branch deployments
resource "azuread_application_federated_identity_credential" "all_branches" {
  application_id = azuread_application.github_actions.id
  display_name   = "homecare-branches"
  description    = "All branch deployments"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.github_repo}:ref:refs/heads/*"
}
