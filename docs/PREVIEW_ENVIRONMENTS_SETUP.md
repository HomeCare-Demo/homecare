# PreviewEnvironment Quick Setup Guide

This guide walks you through setting up the PreviewEnvironment feature for automatic pull request previews.

## Prerequisites

- AKS cluster with NGINX ingress controller
- kubectl configured for your cluster
- Docker CLI with access to ghcr.io
- DNS configuration for `*.dev.homecareapp.xyz`

## Step 1: Deploy the Operator

Deploy the PreviewEnvironment operator to your cluster:

```bash
# Deploy to development
./scripts/deploy-operator.sh deploy -e dev

# Or deploy to production
./scripts/deploy-operator.sh deploy -e prod
```

This script will:
- Build the operator Docker image
- Push it to ghcr.io
- Install CRDs and RBAC
- Deploy the operator

## Step 2: Verify Installation

Check that everything is running:

```bash
# Check operator status
./scripts/deploy-operator.sh status

# Manual verification
kubectl get deployment -n homecare-preview-system
kubectl get crd previewenvironments.preview.homecareapp.xyz
```

## Step 3: Test with a Pull Request

Create a pull request against the main branch. The GitHub Actions workflow will automatically:

1. Build a branch-specific Docker image
2. Create a PreviewEnvironment resource
3. Deploy the preview environment
4. Comment on the PR with the preview URL

## Step 4: Monitor Preview Environments

View active preview environments:

```bash
# List all preview environments
kubectl get previewenvironments

# Get detailed info
kubectl get previewenvironments -o wide

# Check specific environment
kubectl describe previewenvironment preview-username-pr123
```

## DNS Configuration

Ensure your DNS is configured to point `*.dev.homecareapp.xyz` to your NGINX ingress controller's load balancer IP:

```bash
# Get ingress IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Configure DNS A record
# *.dev.homecareapp.xyz → <INGRESS_IP>
```

## Troubleshooting

**Operator not starting:**
```bash
kubectl logs -n homecare-preview-system deployment/preview-operator-controller-manager
```

**Preview environment stuck in Creating:**
```bash
kubectl describe previewenvironment <name>
kubectl get events -n <preview-namespace>
```

**Image pull errors:**
- Verify image exists in ghcr.io
- Check cluster can access registry

## Cleanup

To remove everything:

```bash
./scripts/deploy-operator.sh uninstall
```

This will delete all preview environments and remove the operator.