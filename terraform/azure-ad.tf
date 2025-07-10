# Azure AD Application for GitHub Actions
resource "azuread_application" "github_actions" {
  display_name = "${local.app_name}-github-actions"
}

# Service Principal for the Azure AD Application
resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}
