# PreviewEnvironment Quick Setup Guide

This guide will help you quickly set up the PreviewEnvironment feature for automatic PR previews.

## Prerequisites Checklist

- [ ] AKS cluster with NGINX ingress controller installed
- [ ] DNS configured for `*.dev.homecareapp.xyz` pointing to ingress load balancer
- [ ] GitHub repository with required secrets configured
- [ ] `preview` environment configured in GitHub repository
- [ ] kubectl configured to access your AKS cluster
- [ ] Docker installed and logged in to GitHub Container Registry

## Required GitHub Secrets

These should already be configured if you followed the main setup:

```bash
AZURE_CLIENT_ID          # Azure AD app registration ID
AZURE_TENANT_ID          # Azure tenant ID
AZURE_SUBSCRIPTION_ID    # Azure subscription ID
AZURE_RESOURCE_GROUP     # AKS resource group name
AZURE_CLUSTER_NAME       # AKS cluster name
```

## Step 1: Deploy the Preview Operator

```bash
# Clone the repository if not already done
git clone <repository-url>
cd homecare

# Deploy the operator (this will build and push the operator image)
./scripts/deploy-operator.sh

# Verify deployment
kubectl get pods -n homecare-operator-system
kubectl get crd previewenvironments.preview.homecareapp.xyz
```

## Step 2: Test the Setup

### Option A: Create a Test PR

1. Create a new branch with some changes
2. Open a pull request
3. Watch the GitHub Actions workflow run
4. Check the PR comments for the preview URL

### Option B: Manual Test

```bash
# Create a test PreviewEnvironment
kubectl apply -f - <<EOF
apiVersion: preview.homecareapp.xyz/v1
kind: PreviewEnvironment
metadata:
  name: test-preview
spec:
  repoName: "homecare-demo/homecare"
  prNumber: 999
  branch: "test"
  commitSha: "test123"
  githubUsername: "testuser"
  imageTag: "ghcr.io/homecare-demo/homecare:latest"
  ttl: 2
EOF

# Check status
kubectl get previewenvironments
kubectl get all -n previewtestuser-pr999

# Clean up
kubectl delete previewenvironment test-preview
```

## Step 3: Verify DNS and Ingress

```bash
# Get the ingress load balancer IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Test DNS resolution (replace with actual preview URL)
nslookup testuser999test123.dev.homecareapp.xyz

# Test HTTP access (replace with actual IP and URL)
curl -H "Host: testuser999test123.dev.homecareapp.xyz" http://<LOAD_BALANCER_IP>
```

## Step 4: Configure DNS (if not done)

If wildcard DNS is not configured:

1. Get your NGINX ingress load balancer IP:
   ```bash
   kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
   ```

2. Add a wildcard DNS record in your DNS provider:
   ```
   *.dev.homecareapp.xyz -> A -> <LOAD_BALANCER_IP>
   ```

## Troubleshooting Quick Fixes

### Operator Not Starting

```bash
# Check operator logs
kubectl logs -f deployment/homecare-preview-operator-controller-manager -n homecare-operator-system

# Common issues:
# - RBAC permissions
# - CRD not installed
# - Image pull issues
```

### PreviewEnvironment Stuck

```bash
# Check PreviewEnvironment status
kubectl get previewenvironments -o wide

# Check operator logs for errors
kubectl logs deployment/homecare-preview-operator-controller-manager -n homecare-operator-system --tail=50

# Check events in the preview namespace
kubectl get events -n preview<username>-pr<number> --sort-by=.metadata.creationTimestamp
```

### GitHub Actions Failing

1. **Check OIDC setup**: Verify federated identity credentials in Azure AD
2. **Check cluster access**: Ensure the service principal has AKS permissions
3. **Check image registry**: Verify GITHUB_TOKEN permissions

### Preview Environment Not Accessible

```bash
# Check if ingress is created
kubectl get ingress -A | grep preview

# Check if DNS resolves
nslookup <preview-url>

# Check if pods are running
kubectl get pods -n preview<username>-pr<number>

# Test direct service access
kubectl port-forward -n preview<username>-pr<number> svc/homecare-app 8080:80
# Then visit http://localhost:8080
```

## Usage Examples

### View All Preview Environments

```bash
kubectl get previewenvironments
```

### Get Preview Environment Details

```bash
kubectl get previewenvironment <name> -o yaml
```

### Manual Cleanup

```bash
kubectl delete previewenvironment <name>
```

### Operator Management

```bash
# Restart operator
kubectl rollout restart deployment/homecare-preview-operator-controller-manager -n homecare-operator-system

# Update operator image
./scripts/deploy-operator.sh --force-rebuild

# Uninstall operator
kubectl delete -f operator/config/manager/manager.yaml
kubectl delete -f operator/config/rbac/rbac.yaml
kubectl delete -f operator/config/crd/previewenvironments.yaml
kubectl delete namespace homecare-operator-system
```

## Next Steps

1. **Test PR Workflow**: Create a test PR to see the full workflow
2. **Configure Monitoring**: Set up monitoring for preview environments
3. **Customize TTL**: Adjust default TTL based on your needs
4. **Set up Alerts**: Configure alerts for failed deployments

## Support

For detailed documentation, see [PREVIEW_ENVIRONMENT.md](PREVIEW_ENVIRONMENT.md).

For issues:
1. Check operator logs
2. Verify GitHub Actions workflow logs
3. Check Kubernetes events
4. Review DNS configuration