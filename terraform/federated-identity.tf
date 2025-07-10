# Federated Identity Credentials for GitHub Actions OIDC

# All branch deployments (includes main, dev, feature branches)
resource "azuread_application_federated_identity_credential" "all_branches" {
  application_id = azuread_application.github_actions.id
  display_name   = "homecare-branches"
  description    = "All branch deployments including main"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.github_repo}:ref:refs/heads/*"
}

# Release deployments (tags)
resource "azuread_application_federated_identity_credential" "releases" {
  application_id = azuread_application.github_actions.id
  display_name   = "homecare-releases"
  description    = "Release deployment via tags"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.github_repo}:ref:refs/tags/*"
}
