#!/bin/bash

# Enhanced deployment script for HomeCarepreviwoperator
# Usage: ./deploy-operator.sh [dev|prod]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OPERATOR_DIR="${PROJECT_ROOT}/k8s/operators"
REGISTRY="ghcr.io/homecare-demo/homecare"
OPERATOR_IMAGE="${REGISTRY}/homecare-preview-operator"

# Default environment
ENVIRONMENT="${1:-dev}"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    echo "Error: Environment must be 'dev' or 'prod'"
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

# Set image tag based on environment
if [[ "$ENVIRONMENT" == "dev" ]]; then
    IMAGE_TAG="dev"
else
    IMAGE_TAG="latest"
fi

FULL_IMAGE="${OPERATOR_IMAGE}:${IMAGE_TAG}"

echo "🚀 Deploying HomeCarepreviwoperator to $ENVIRONMENT environment"
echo "📦 Image: $FULL_IMAGE"

# Function to check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if docker is available
    if ! command -v docker &> /dev/null; then
        echo "❌ docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check if connected to Kubernetes cluster
    if ! kubectl cluster-info &> /dev/null; then
        echo "❌ Not connected to a Kubernetes cluster"
        echo "   Please ensure you have access to your AKS cluster"
        exit 1
    fi
    
    # Check if in correct directory
    if [[ ! -d "$OPERATOR_DIR" ]]; then
        echo "❌ Operator directory not found: $OPERATOR_DIR"
        exit 1
    fi
    
    echo "✅ Prerequisites check passed"
}

# Function to authenticate with container registry
authenticate_registry() {
    echo "🔐 Authenticating with container registry..."
    
    # Check if already logged in by trying to list repositories
    if docker pull "${REGISTRY}/homecare:latest" 2>/dev/null | grep -q "Image is up to date" || \
       docker pull "${REGISTRY}/homecare:latest" 2>/dev/null | grep -q "Downloaded newer image"; then
        echo "✅ Already authenticated with registry"
        return 0
    fi
    
    # Try to authenticate using GitHub token if available
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        echo "$GITHUB_TOKEN" | docker login ghcr.io -u homecare-demo --password-stdin
        echo "✅ Authenticated using GITHUB_TOKEN"
    else
        echo "⚠️  GITHUB_TOKEN not found. You may need to login manually:"
        echo "   docker login ghcr.io -u homecare-demo"
        echo "   or set GITHUB_TOKEN environment variable"
        
        # Try interactive login
        docker login ghcr.io -u homecare-demo || {
            echo "❌ Failed to authenticate with registry"
            exit 1
        }
    fi
}

# Function to build and push operator image
build_and_push_operator() {
    echo "🏗️  Building operator image..."
    
    cd "$OPERATOR_DIR"
    
    # Build for multi-platform (ARM64 + AMD64)
    echo "Building multi-platform image: $FULL_IMAGE"
    
    # Create buildx builder if it doesn't exist
    if ! docker buildx ls | grep -q "homecare-builder"; then
        docker buildx create --name homecare-builder --use
    else
        docker buildx use homecare-builder
    fi
    
    # Build and push multi-platform image
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --tag "$FULL_IMAGE" \
        --push \
        .
    
    echo "✅ Successfully built and pushed: $FULL_IMAGE"
}

# Function to install CRDs
install_crds() {
    echo "📋 Installing Custom Resource Definitions..."
    
    cd "$OPERATOR_DIR"
    
    # Generate the latest manifests
    echo "Generating manifests..."
    make manifests
    
    # Install CRDs
    kubectl apply -f config/crd/bases/
    
    echo "✅ CRDs installed successfully"
}

# Function to deploy operator
deploy_operator() {
    echo "🚀 Deploying operator..."
    
    cd "$OPERATOR_DIR"
    
    # Create namespace for operator if it doesn't exist
    kubectl create namespace homecare-system --dry-run=client -o yaml | kubectl apply -f -
    
    # Set the image in the manager configuration
    cd config/manager
    
    # Create a temporary kustomization that sets the image
    cat > kustomization-temp.yaml << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- .

images:
- name: controller
  newName: ${OPERATOR_IMAGE}
  newTag: ${IMAGE_TAG}

namespace: homecare-system
EOF
    
    # Apply the operator
    kubectl apply -k . --kustomization=kustomization-temp.yaml
    
    # Clean up temporary file
    rm -f kustomization-temp.yaml
    
    echo "✅ Operator deployed successfully"
}

# Function to wait for operator to be ready
wait_for_operator() {
    echo "⏳ Waiting for operator to be ready..."
    
    # Wait for deployment to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/homecare-preview-operator-controller-manager -n homecare-system
    
    echo "✅ Operator is ready!"
}

# Function to display status
show_status() {
    echo ""
    echo "📊 Deployment Status:"
    echo "===================="
    
    echo ""
    echo "🔧 Operator Status:"
    kubectl get deployment homecare-preview-operator-controller-manager -n homecare-system -o wide
    
    echo ""
    echo "📋 Custom Resource Definitions:"
    kubectl get crd | grep preview.homecareapp.xyz
    
    echo ""
    echo "🏠 Preview Environments:"
    kubectl get previewenvironments --all-namespaces || echo "No preview environments found"
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Create a PreviewEnvironment resource to test the operator"
    echo "   2. Monitor operator logs: kubectl logs -f deployment/homecare-preview-operator-controller-manager -n homecare-system"
    echo "   3. Check operator status: kubectl get pods -n homecare-system"
}

# Function to handle cleanup on failure
cleanup_on_failure() {
    echo "❌ Deployment failed! Check the logs above for details."
    echo ""
    echo "🔍 Troubleshooting tips:"
    echo "   1. Check operator logs: kubectl logs -f deployment/homecare-preview-operator-controller-manager -n homecare-system"
    echo "   2. Check pod status: kubectl get pods -n homecare-system"
    echo "   3. Check events: kubectl get events -n homecare-system"
    echo ""
    echo "🧹 To clean up and retry:"
    echo "   kubectl delete namespace homecare-system"
    echo "   kubectl delete crd previewenvironments.preview.homecareapp.xyz"
    exit 1
}

# Main execution
main() {
    echo "🏠 HomeCare Preview Environment Operator Deployment"
    echo "================================================="
    echo ""
    
    # Set up error handling
    trap cleanup_on_failure ERR
    
    check_prerequisites
    authenticate_registry
    build_and_push_operator
    install_crds
    deploy_operator
    wait_for_operator
    show_status
}

# Run main function
main "$@"
