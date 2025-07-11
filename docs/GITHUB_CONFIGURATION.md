# GitHub Configuration with Terraform

This document explains how the GitHub repository is configured automatically using Terraform, including environments, secrets, and branch protection rules.

## Overview

The `github.tf` file configures the following GitHub repository settings:

- **Environments**: `dev` and `prod` with deployment protection rules
- **Secrets**: Azure credentials for OIDC authentication
- **Branch Protection**: Main branch protection with review requirements
- **Repository Settings**: Security settings, topics, and merge policies

## GitHub Personal Access Token Setup

### Required Permissions

Create a GitHub Personal Access Token with the following permissions:

- `repo` - Full control of private repositories
- `admin:repo_hook` - Admin repository hooks  
- `admin:org` - Full control of organizations and teams (if repository is in an organization)

### Creating the Token

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Select the required permissions above
4. Set an appropriate expiration date
5. Generate and copy the token

### Adding to Terraform Cloud

1. Go to your Terraform Cloud workspace
2. Navigate to Variables
3. Add a new environment variable:
   - **Variable name**: `TF_VAR_github_token`
   - **Value**: Your GitHub PAT
   - **Category**: Environment variable
   - **Sensitive**: ✅ (checked)

## Configured GitHub Resources

### Environments

#### Development Environment (`dev`)
- **Deployment Policy**: Custom branch policies enabled
- **Protection**: Allows deployments from any branch
- **Use Case**: Testing features and development work

#### Production Environment (`prod`)  
- **Deployment Policy**: Protected branches only
- **Protection**: Only allows deployments from protected branches (main)
- **Use Case**: Production releases and stable deployments

### Repository Secrets

The following secrets are automatically configured for GitHub Actions:

| Secret Name | Source | Purpose |
|-------------|--------|---------|
| `AZURE_CLIENT_ID` | Azure AD App Registration | OIDC authentication client ID |
| `AZURE_TENANT_ID` | Azure tenant | Azure tenant identifier |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription | Target subscription for deployments |
| `AZURE_RESOURCE_GROUP` | Terraform resource | Resource group containing AKS cluster |
| `AZURE_CLUSTER_NAME` | Terraform resource | AKS cluster name for kubectl configuration |

### Branch Protection Rules

#### Main Branch Protection
- **Pull Request Reviews**: Required (1 approving review)
- **Status Checks**: Required (build job must pass)
- **Dismiss Stale Reviews**: Enabled
- **Force Push**: Allowed (can be restricted)
- **Delete Branch**: Blocked

### Repository Settings

#### Security Features
- **Vulnerability Alerts**: Enabled
- **Delete Branch on Merge**: Enabled
- **Merge Options**: All types allowed (merge, squash, rebase)
- **Auto Merge**: Disabled

#### Repository Topics
- `homecare`, `home-maintenance`, `nextjs`, `typescript`
- `azure`, `kubernetes`, `aks`, `terraform`
- `docker`, `tailwindcss`

## Deployment Workflow Integration

### Manual Deployments

The GitHub Actions workflow supports manual deployments:

1. Go to **Actions** tab in your repository
2. Select **Deploy to AKS** workflow
3. Click **Run workflow**
4. Choose environment (`dev` or `prod`)
5. Optionally specify an image tag

### Automatic Production Deployment

Production deployments are triggered automatically when:

1. A new GitHub release is published
2. The workflow runs the `build` job
3. Deploys to the `prod` environment automatically

### Environment Protection

#### Development Environment
- ✅ Allows deployments from feature branches
- ✅ Immediate deployment without approval
- ✅ Useful for testing and development

#### Production Environment  
- 🔒 Only allows deployments from protected branches
- 🔒 Can be configured to require manual approval
- 🔒 Ensures stable, reviewed code reaches production

## Terraform Outputs

After applying the configuration, Terraform provides helpful outputs:

```hcl
github_configuration_summary = {
  repository_url = "https://github.com/mvkaran/homecare"
  environments_created = ["dev", "prod"]
  secrets_configured = [
    "AZURE_CLIENT_ID",
    "AZURE_TENANT_ID", 
    "AZURE_SUBSCRIPTION_ID",
    "AZURE_RESOURCE_GROUP",
    "AZURE_CLUSTER_NAME"
  ]
  workflow_file = ".github/workflows/deploy.yml"
  deployment_notes = [
    "Development environment: Allows custom branch deployments",
    "Production environment: Only protected branches allowed",
    "Manual deployments available via GitHub Actions workflow_dispatch",
    "Automatic production deployment on GitHub releases"
  ]
}
```

## Troubleshooting

### Common Issues

#### 1. GitHub Token Permissions
**Error**: `Resource not accessible by integration`
**Solution**: Ensure your GitHub token has the required permissions (`repo`, `admin:repo_hook`, `admin:org`)

#### 2. Repository Not Found
**Error**: `Repository not found`
**Solution**: 
- Verify the repository name is correct in `github.tf`
- Ensure your GitHub token has access to the repository
- Check if repository is private and token has appropriate permissions

#### 3. Branch Protection Conflicts
**Error**: `Branch protection rule conflicts`
**Solution**: 
- Check existing branch protection rules in GitHub
- Modify the Terraform configuration to match existing rules
- Or remove existing rules to let Terraform manage them

### Verifying Configuration

After applying Terraform, verify the configuration:

1. **Environments**: Go to repository Settings → Environments
2. **Secrets**: Go to repository Settings → Secrets and variables → Actions
3. **Branch Protection**: Go to repository Settings → Branches
4. **Repository Settings**: Go to repository Settings → General

## Manual Configuration (Alternative)

If you prefer to configure GitHub manually instead of using Terraform:

### 1. Create Environments
```bash
# Using GitHub CLI
gh api repos/mvkaran/homecare/environments -f name=dev
gh api repos/mvkaran/homecare/environments -f name=prod
```

### 2. Add Secrets
```bash
# Using GitHub CLI (replace <VALUE> with actual values)
gh secret set AZURE_CLIENT_ID -b "<VALUE>" --repo mvkaran/homecare
gh secret set AZURE_TENANT_ID -b "<VALUE>" --repo mvkaran/homecare
gh secret set AZURE_SUBSCRIPTION_ID -b "<VALUE>" --repo mvkaran/homecare
gh secret set AZURE_RESOURCE_GROUP -b "<VALUE>" --repo mvkaran/homecare
gh secret set AZURE_CLUSTER_NAME -b "<VALUE>" --repo mvkaran/homecare
```

### 3. Configure Branch Protection
Use the GitHub web interface:
- Go to Settings → Branches
- Add rule for `main` branch
- Enable required status checks and pull request reviews

## Best Practices

1. **Rotate GitHub Tokens**: Regularly rotate your personal access tokens
2. **Use Fine-grained Tokens**: Consider GitHub's fine-grained personal access tokens for better security
3. **Environment Reviews**: Consider adding required reviewers for production environment
4. **Status Checks**: Add additional required status checks as your CI/CD pipeline grows
5. **Secrets Rotation**: Implement a process for rotating Azure credentials periodically

## References

- [GitHub Environments Documentation](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [GitHub Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [Terraform GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest/docs)
- [Azure OIDC with GitHub Actions](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure)
