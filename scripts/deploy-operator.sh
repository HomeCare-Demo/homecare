#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
BUILD_PUSH_IMAGES=true
NAMESPACE="homecare-operator-system"
IMAGE_TAG=""
FORCE_REBUILD=false

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OPERATOR_DIR="${REPO_ROOT}/operator"

# Usage function
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Deploy the HomeCare Preview Operator to Kubernetes"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV     Target environment (dev|prod) [default: dev]"
    echo "  -t, --tag TAG            Image tag to use [default: auto-generated]"
    echo "  -n, --namespace NAME     Kubernetes namespace [default: homecare-operator-system]"
    echo "  --no-build               Skip building and pushing images"
    echo "  --force-rebuild          Force rebuild even if image exists"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                       # Deploy to dev with auto-generated tag"
    echo "  $0 -e prod -t v1.0.0     # Deploy to prod with specific tag"
    echo "  $0 --no-build            # Deploy without building new images"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --no-build)
            BUILD_PUSH_IMAGES=false
            shift
            ;;
        --force-rebuild)
            FORCE_REBUILD=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    echo -e "${RED}Error: Environment must be 'dev' or 'prod'${NC}"
    exit 1
fi

# Generate image tag if not provided
if [[ -z "$IMAGE_TAG" ]]; then
    if [[ "$ENVIRONMENT" == "dev" ]]; then
        IMAGE_TAG="dev"
    else
        IMAGE_TAG="latest"
    fi
fi

# Configuration
OPERATOR_IMAGE="ghcr.io/mvkaran/homecare/homecare-preview-operator:${IMAGE_TAG}"

# Helper functions
print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check required tools
    local tools=("kubectl" "docker")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            print_error "$tool is required but not installed"
            exit 1
        fi
    done

    # Check kubectl context
    if ! kubectl cluster-info &> /dev/null; then
        print_error "kubectl is not connected to a cluster"
        exit 1
    fi

    # Check Docker daemon
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi

    print_success "Prerequisites check passed"
}

build_and_push_operator() {
    if [[ "$BUILD_PUSH_IMAGES" != "true" ]]; then
        print_status "Skipping image build (--no-build specified)"
        return 0
    fi

    print_status "Building and pushing operator image..."
    
    cd "$OPERATOR_DIR"

    # Check if image exists (unless force rebuild)
    if [[ "$FORCE_REBUILD" != "true" ]]; then
        if docker manifest inspect "$OPERATOR_IMAGE" &> /dev/null; then
            print_warning "Image $OPERATOR_IMAGE already exists, skipping build"
            print_warning "Use --force-rebuild to force rebuild"
            return 0
        fi
    fi

    # Build the operator image
    print_status "Building operator image: $OPERATOR_IMAGE"
    docker build -t "$OPERATOR_IMAGE" .

    # Push the image
    print_status "Pushing operator image to registry..."
    docker push "$OPERATOR_IMAGE"

    print_success "Operator image built and pushed successfully"
}

create_namespace() {
    print_status "Creating namespace: $NAMESPACE"
    
    # Create namespace if it doesn't exist
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        kubectl create namespace "$NAMESPACE"
        print_success "Namespace $NAMESPACE created"
    else
        print_warning "Namespace $NAMESPACE already exists"
    fi

    # Label the namespace
    kubectl label namespace "$NAMESPACE" \
        app.kubernetes.io/name=homecare-preview-operator \
        app.kubernetes.io/component=operator \
        app.kubernetes.io/part-of=homecare \
        --overwrite

    print_success "Namespace configuration updated"
}

install_crd() {
    print_status "Installing Custom Resource Definitions..."
    
    cd "$OPERATOR_DIR"
    
    # Apply CRD
    kubectl apply -f config/crd/previewenvironments.yaml
    
    # Wait for CRD to be established
    print_status "Waiting for CRD to be established..."
    kubectl wait --for=condition=Established crd/previewenvironments.preview.homecareapp.xyz --timeout=60s
    
    print_success "CRDs installed successfully"
}

install_rbac() {
    print_status "Installing RBAC configuration..."
    
    cd "$OPERATOR_DIR"
    
    # Update namespace in RBAC configuration
    sed "s/namespace: homecare-operator-system/namespace: $NAMESPACE/g" config/rbac/rbac.yaml | kubectl apply -f -
    
    print_success "RBAC configuration installed"
}

deploy_operator() {
    print_status "Deploying operator..."
    
    cd "$OPERATOR_DIR"
    
    # Create temporary deployment file with correct image and namespace
    local temp_deployment="/tmp/operator-deployment.yaml"
    sed -e "s|namespace: homecare-operator-system|namespace: $NAMESPACE|g" \
        -e "s|image: ghcr.io/mvkaran/homecare/homecare-preview-operator:latest|image: $OPERATOR_IMAGE|g" \
        config/manager/manager.yaml > "$temp_deployment"
    
    # Apply the deployment
    kubectl apply -f "$temp_deployment"
    
    # Clean up temp file
    rm -f "$temp_deployment"
    
    # Wait for deployment to be ready
    print_status "Waiting for operator deployment to be ready..."
    kubectl rollout status deployment/homecare-preview-operator-controller-manager \
        -n "$NAMESPACE" --timeout=300s
    
    print_success "Operator deployed successfully"
}

verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check if operator pod is running
    local pod_status
    pod_status=$(kubectl get pods -n "$NAMESPACE" \
        -l app.kubernetes.io/name=homecare-preview-operator \
        --no-headers -o custom-columns=":status.phase" | head -1)
    
    if [[ "$pod_status" == "Running" ]]; then
        print_success "Operator pod is running"
    else
        print_error "Operator pod is not running (status: $pod_status)"
        return 1
    fi
    
    # Check CRD
    if kubectl get crd previewenvironments.preview.homecareapp.xyz &> /dev/null; then
        print_success "PreviewEnvironment CRD is installed"
    else
        print_error "PreviewEnvironment CRD is not installed"
        return 1
    fi
    
    # Show deployment status
    echo ""
    print_status "Deployment Status:"
    echo "==================="
    echo "📦 Operator Image: $OPERATOR_IMAGE"
    echo "🎯 Environment: $ENVIRONMENT"
    echo "📁 Namespace: $NAMESPACE"
    echo ""
    echo "🚀 Pods:"
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=homecare-preview-operator
    echo ""
    echo "📋 Custom Resource Definitions:"
    kubectl get crd | grep previewenvironments
    echo ""
    
    print_success "Deployment verification completed"
}

show_usage_examples() {
    echo ""
    print_status "Usage Examples:"
    echo "==============="
    echo ""
    echo "📋 List PreviewEnvironments:"
    echo "   kubectl get previewenvironments"
    echo ""
    echo "🚀 Create a test PreviewEnvironment:"
    cat << 'EOF'
   kubectl apply -f - <<YAML
apiVersion: preview.homecareapp.xyz/v1
kind: PreviewEnvironment
metadata:
  name: test-preview
spec:
  repoName: "homecare-demo/homecare"
  prNumber: 123
  branch: "feature/test"
  commitSha: "abc1234"
  githubUsername: "testuser"
  imageTag: "ghcr.io/homecare-demo/homecare:test"
  ttl: 2
YAML
EOF
    echo ""
    echo "🔍 Check PreviewEnvironment status:"
    echo "   kubectl get previewenvironments test-preview -o yaml"
    echo ""
    echo "🗑️  Delete PreviewEnvironment:"
    echo "   kubectl delete previewenvironment test-preview"
    echo ""
    echo "📊 View operator logs:"
    echo "   kubectl logs -f deployment/homecare-preview-operator-controller-manager -n $NAMESPACE"
}

# Main execution
main() {
    echo -e "${BLUE}🏠 HomeCare Preview Operator Deployment${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    check_prerequisites
    echo ""
    
    if [[ "$BUILD_PUSH_IMAGES" == "true" ]]; then
        build_and_push_operator
        echo ""
    fi
    
    create_namespace
    echo ""
    
    install_crd
    echo ""
    
    install_rbac
    echo ""
    
    deploy_operator
    echo ""
    
    verify_deployment
    
    show_usage_examples
    
    echo ""
    print_success "🎉 HomeCare Preview Operator deployment completed successfully!"
    echo ""
}

# Run main function
main "$@"