#!/bin/bash

# Script to configure GitHub Container Registry pull secrets for Kubernetes
# Usage: ./configure-pull-secrets.sh
# 
# Prerequisites:
# - kubectl configured with cluster access
# - Valid GitHub personal access token with packages:read permission

set -euo pipefail

# Function to read input securely
read_secret() {
    local prompt="$1"
    local secret
    echo -n "$prompt" >&2
    read -s secret
    echo >&2
    echo "$secret"
}

# Function to validate environment input
validate_environment() {
    local env="$1"
    if [[ "$env" != "dev" && "$env" != "prod" ]]; then
        return 1
    fi
    return 0
}

echo "🔧 GitHub Container Registry Pull Secret Configuration"
echo "====================================================="
echo ""
echo "This script will help you configure Kubernetes pull secrets"
echo "to access private images from GitHub Container Registry (ghcr.io)."
echo ""

# Get environment
while true; do
    echo "📋 Available environments:"
    echo "   - dev  (development)"
    echo "   - prod (production)"
    echo ""
    read -p "Enter target environment [dev]: " ENVIRONMENT
    ENVIRONMENT="${ENVIRONMENT:-dev}"
    
    if validate_environment "$ENVIRONMENT"; then
        break
    else
        echo "❌ Invalid environment. Please enter 'dev' or 'prod'."
        echo ""
    fi
done

# Configuration
REGISTRY="ghcr.io"
SECRET_NAME="ghcr-pull-secret"
NAMESPACE="homecare-${ENVIRONMENT}"

echo ""
echo "🔐 Authentication Details"
echo "========================"
echo ""

# Get GitHub username
read -p "Enter your GitHub username: " GITHUB_USERNAME
if [[ -z "$GITHUB_USERNAME" ]]; then
    echo "❌ Error: GitHub username cannot be empty"
    exit 1
fi

echo ""
echo "🔑 GitHub Personal Access Token"
echo "==============================="
echo ""
echo "You need a GitHub Personal Access Token with 'packages:read' permission."
echo "To create one:"
echo "  1. Go to: https://github.com/settings/tokens"
echo "  2. Click 'Generate new token (classic)'"
echo "  3. Select 'packages:read' scope"
echo "  4. Copy the generated token"
echo ""

# Get GitHub token securely
GITHUB_TOKEN=$(read_secret "Enter your GitHub Personal Access Token (input hidden): ")
if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "❌ Error: GitHub token cannot be empty"
    exit 1
fi

echo ""
echo "� Configuration Summary"
echo "======================="
echo "   Registry: ${REGISTRY}"
echo "   Username: ${GITHUB_USERNAME}"
echo "   Environment: ${ENVIRONMENT}"
echo "   Namespace: ${NAMESPACE}"
echo "   Secret Name: ${SECRET_NAME}"
echo ""

# Confirm before proceeding
read -p "Do you want to proceed with this configuration? [Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-Y}"
if [[ "$CONFIRM" != "Y" && "$CONFIRM" != "y" && "$CONFIRM" != "yes" ]]; then
    echo "❌ Configuration cancelled."
    exit 0
fi

echo ""
echo "🚀 Starting configuration..."
echo ""

# Check kubectl connectivity
echo "🔍 Checking Kubernetes connectivity..."
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "❌ Error: Unable to connect to Kubernetes cluster"
    echo "   Please ensure kubectl is properly configured"
    exit 1
fi
echo "✅ Connected to Kubernetes cluster"

# Create namespace if it doesn't exist
echo "📁 Creating namespace if it doesn't exist..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# Create or update the docker-registry secret
echo "🔐 Creating/updating image pull secret..."
kubectl create secret docker-registry "${SECRET_NAME}" \
    --namespace="${NAMESPACE}" \
    --docker-server="${REGISTRY}" \
    --docker-username="${GITHUB_USERNAME}" \
    --docker-password="${GITHUB_TOKEN}" \
    --dry-run=client -o yaml | kubectl apply -f -

# Verify the secret was created
echo "✅ Verifying secret creation..."
if kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1; then
    echo "✅ Secret '${SECRET_NAME}' successfully configured in namespace '${NAMESPACE}'"
    
    # Show secret details (without exposing sensitive data)
    echo ""
    echo "📋 Secret details:"
    kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" -o wide
else
    echo "❌ Failed to create or verify secret"
    exit 1
fi

echo ""
echo "🎉 Pull secret configuration completed successfully!"
echo ""
echo "💡 Next steps:"
echo "   1. Ensure your Kubernetes deployment uses imagePullSecrets:"
echo "      spec:"
echo "        template:"
echo "          spec:"
echo "            imagePullSecrets:"
echo "            - name: ${SECRET_NAME}"
echo ""
echo "   2. Deploy your application with the updated manifests"
echo ""
echo "🔐 Security note: Your GitHub token has been securely stored in the cluster"
echo "   and is not visible in the Kubernetes manifests or logs."
