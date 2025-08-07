# PreviewEnvironment Feature Documentation

## Overview

The PreviewEnvironment feature provides automatic preview deployments for pull requests using a custom Kubernetes operator. Each pull request gets its own isolated environment with a unique URL for testing and review.

## Architecture

### Components

1. **Custom Resource Definition (CRD)**: Defines PreviewEnvironment resources
2. **Kubernetes Operator**: Manages the lifecycle of preview environments  
3. **GitHub Actions Workflow**: Automates preview environment deployment
4. **Enhanced Deployment Script**: Handles operator deployment and management

### Resource Management

The PreviewEnvironment CRD acts as a single source of truth for all preview environment resources:

- **Dedicated Namespace**: Each preview gets its own isolated namespace
- **Owner References**: All resources are owned by the PreviewEnvironment
- **Automatic Cleanup**: Deleting the PreviewEnvironment cascades to all resources
- **TTL Management**: Automatic expiration after configured time

## Quick Start

### 1. Deploy the Operator

Deploy the PreviewEnvironment operator to your cluster:

```bash
# Deploy to development environment
./scripts/deploy-operator.sh deploy -e dev

# Deploy to production environment  
./scripts/deploy-operator.sh deploy -e prod

# Check deployment status
./scripts/deploy-operator.sh status
```

### 2. Configure GitHub Actions

The GitHub Actions workflow is already configured in `.github/workflows/preview.yml`. It will:

- Trigger on PR open/sync/reopen/close events
- Build branch-specific Docker images
- Create PreviewEnvironment resources
- Update PRs with preview URLs
- Clean up on PR closure

### 3. Create a Pull Request

Once the operator is deployed, simply create a pull request against the main branch. The workflow will automatically:

1. Build a Docker image with tag: `preview<username>-pr<number><commit>`
2. Create a PreviewEnvironment resource
3. Deploy the application to a dedicated namespace
4. Comment on the PR with the preview URL

## PreviewEnvironment Resource Specification

### Spec Fields

```yaml
apiVersion: preview.homecareapp.xyz/v1
kind: PreviewEnvironment
metadata:
  name: preview-username-pr123
spec:
  repoName: "homecare"           # Repository name
  prNumber: 123                  # Pull request number  
  branch: "feature-branch"       # Source branch name
  commitSha: "abc1234567"        # Commit SHA to deploy
  githubUsername: "username"     # GitHub username
  imageTag: "ghcr.io/..."       # Docker image to deploy
  ttl: 72                        # TTL in hours (default: 24)
```

### Status Fields

```yaml
status:
  phase: "Ready"                           # Creating|Ready|Expiring|Failed
  environmentUrl: "https://username123abc1234.dev.homecareapp.xyz"
  namespace: "previewusername-pr123"       # Created namespace
  createdAt: "2025-01-07T10:00:00Z"       # Creation timestamp
  expiresAt: "2025-01-10T10:00:00Z"       # Expiration timestamp
  message: "Preview environment is ready"  # Status message
  conditions: []                           # Standard conditions
```

## URL Pattern

Preview environments are accessible at:
```
https://<username><pr><commit>.dev.homecareapp.xyz
```

Example: `https://john123abc1234.dev.homecareapp.xyz`

## Resource Isolation

Each preview environment includes:

- **Dedicated Namespace**: `preview<username>-pr<number>`
- **Deployment**: Single replica with optimized resources
- **Service**: ClusterIP service for internal communication
- **Ingress**: NGINX ingress with unique hostname
- **Labels**: Consistent labeling for management

### Resource Limits

Optimized for cost-efficiency:
- **CPU Request**: 50m
- **CPU Limit**: 100m  
- **Memory Request**: 32Mi
- **Memory Limit**: 64Mi

## TTL and Cleanup

### Automatic Expiration

Preview environments automatically expire based on TTL:
- **Default TTL**: 24 hours
- **Maximum TTL**: 168 hours (7 days)
- **GitHub Actions TTL**: 72 hours (3 days)

### Manual Cleanup

```bash
# List all preview environments
kubectl get previewenvironments

# Delete specific environment
kubectl delete previewenvironment preview-username-pr123

# Delete all environments
kubectl delete previewenvironments --all
```

### Cleanup on PR Close

When a PR is closed, the GitHub Actions workflow automatically deletes the PreviewEnvironment resource, which triggers cascading cleanup of all associated resources.

## Operator Management

### Deployment Script Usage

```bash
# Show help
./scripts/deploy-operator.sh --help

# Deploy with custom settings
./scripts/deploy-operator.sh deploy -e prod -t v1.0.0

# Build image only
./scripts/deploy-operator.sh build -t latest

# Check status
./scripts/deploy-operator.sh status

# Uninstall everything
./scripts/deploy-operator.sh uninstall
```

### Manual Operations

```bash
# Check operator status
kubectl get deployment -n homecare-preview-system

# View operator logs
kubectl logs -n homecare-preview-system deployment/preview-operator-controller-manager

# Check CRD
kubectl get crd previewenvironments.preview.homecareapp.xyz

# View all preview environments
kubectl get previewenvironments -o wide
```

## Troubleshooting

### Common Issues

**Preview Environment Stuck in Creating**
```bash
# Check operator logs
kubectl logs -n homecare-preview-system deployment/preview-operator-controller-manager

# Check events in preview namespace
kubectl get events -n preview<username>-pr<number> --sort-by=.metadata.creationTimestamp
```

**Image Pull Errors**
- Verify image exists in registry
- Check image tag in PreviewEnvironment spec
- Ensure cluster can access ghcr.io

**Ingress Not Working**
- Verify NGINX ingress controller is running
- Check DNS configuration for *.dev.homecareapp.xyz
- Verify ingress resource creation

**Resource Cleanup Issues**
- Check finalizers on PreviewEnvironment resource
- Verify operator is running and healthy
- Check RBAC permissions

### Debugging Commands

```bash
# Describe preview environment
kubectl describe previewenvironment preview-username-pr123

# Check created resources
kubectl get all -n preview<username>-pr<number>

# View ingress details
kubectl describe ingress -n preview<username>-pr<number>

# Check resource ownership
kubectl get <resource> -o yaml | grep ownerReferences
```

## Security Considerations

### RBAC Permissions

The operator requires cluster-wide permissions for:
- Managing namespaces
- Creating deployments, services, ingresses
- Reading/writing PreviewEnvironment resources

### Network Security

- Preview environments use dedicated namespaces for isolation
- Ingress controller handles external access
- No direct internet access from preview pods

### Resource Limits

- Strict resource quotas prevent resource exhaustion
- TTL enforcement prevents long-running environments
- Automatic cleanup on PR closure

## Cost Optimization

### Resource Efficiency

- Single replica deployments
- Minimal CPU/memory requests
- ARM64-compatible images for better price/performance
- Automatic cleanup based on TTL

### Monitoring

Monitor preview environment usage:

```bash
# Count active environments
kubectl get previewenvironments --no-headers | wc -l

# Resource usage by namespace
kubectl top pods --all-namespaces | grep preview

# Check expiration times
kubectl get previewenvironments -o custom-columns=NAME:.metadata.name,EXPIRES:.status.expiresAt
```

## Integration with Existing Infrastructure

### AKS Integration

- Uses existing AKS cluster and node pools
- Leverages existing NGINX ingress controller
- Integrates with existing DNS configuration

### GitHub Integration

- Uses existing OIDC authentication
- Leverages GitHub Container Registry
- Integrates with PR workflows and status checks

### Terraform Integration

- Operator deployed independently of Terraform
- Uses GitHub environments configured by Terraform
- Respects existing RBAC and networking setup

## Future Enhancements

- **Database Integration**: Support for preview databases
- **SSL Certificates**: Automatic TLS certificate management
- **Resource Scaling**: Dynamic resource scaling based on usage
- **Cost Reporting**: Detailed cost tracking per preview environment
- **Slack Integration**: Notifications for preview environment status