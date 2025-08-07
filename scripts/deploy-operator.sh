#!/bin/bash

# Enhanced Preview Environment Operator Deployment Script
# Handles operator image building, pushing, and deployment

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OPERATOR_DIR="${PROJECT_ROOT}/operator"
REGISTRY="ghcr.io"
IMAGE_NAME="${REGISTRY}/homecare-demo/homecare/homecare-preview-operator"
DEFAULT_TAG="latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Enhanced Preview Environment Operator Deployment Script

USAGE:
    $0 [OPTIONS] [COMMAND]

COMMANDS:
    build       Build operator image only
    push        Build and push operator image
    deploy      Build, push, and deploy operator (default)
    install     Install CRD and RBAC only (no operator deployment)
    uninstall   Remove operator and CRDs
    status      Check operator status

OPTIONS:
    -e, --environment ENV    Target environment (dev|prod) [default: dev]
    -t, --tag TAG           Image tag [default: latest for prod, dev for dev env]
    -n, --namespace NS      Operator namespace [default: homecare-preview-system]
    --no-build              Skip building image (use existing)
    --dry-run               Show what would be done without executing
    -h, --help              Show this help message

EXAMPLES:
    $0                              # Deploy to dev with default settings
    $0 deploy -e prod -t v1.0.0     # Deploy to prod with specific tag
    $0 build -t latest              # Build image with latest tag
    $0 status                       # Check operator status
    $0 uninstall                    # Remove operator and CRDs

PREREQUISITES:
    - Docker CLI with access to $REGISTRY
    - kubectl configured for target cluster
    - Operator source code in ${OPERATOR_DIR}

EOF
}

# Parse arguments
COMMAND="deploy"
ENVIRONMENT="dev"
TAG=""
NAMESPACE="homecare-preview-system"
NO_BUILD=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        build|push|deploy|install|uninstall|status)
            COMMAND="$1"
            shift
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --no-build)
            NO_BUILD=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Set default tag based on environment
if [[ -z "$TAG" ]]; then
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        TAG="$DEFAULT_TAG"
    else
        TAG="dev"
    fi
fi

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    log_error "Environment must be 'dev' or 'prod'"
    exit 1
fi

# Full image reference
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

# Dry run function
execute() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would execute: $*"
    else
        log_info "Executing: $*"
        "$@"
    fi
}

# Prerequisite checks
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if we're in the right directory
    if [[ ! -d "$OPERATOR_DIR" ]]; then
        log_error "Operator directory not found: $OPERATOR_DIR"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker CLI not found. Please install Docker."
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    # Check if operator directory has required files
    if [[ ! -f "$OPERATOR_DIR/Dockerfile" ]]; then
        log_error "Dockerfile not found in operator directory"
        exit 1
    fi
    
    if [[ ! -f "$OPERATOR_DIR/Makefile" ]]; then
        log_error "Makefile not found in operator directory"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Build operator image
build_image() {
    if [[ "$NO_BUILD" == "true" ]]; then
        log_info "Skipping image build (--no-build specified)"
        return 0
    fi
    
    log_info "Building operator image: $FULL_IMAGE"
    
    cd "$OPERATOR_DIR"
    
    # Build multi-platform image for compatibility
    execute docker buildx build \
        --platform linux/amd64,linux/arm64 \
        -t "$FULL_IMAGE" \
        --load \
        .
    
    log_success "Image built successfully: $FULL_IMAGE"
}

# Push operator image
push_image() {
    log_info "Pushing operator image: $FULL_IMAGE"
    
    # Check if logged in to registry
    if ! docker info | grep -q "Registry:"; then
        log_info "Logging in to container registry..."
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            echo "$GITHUB_TOKEN" | execute docker login "$REGISTRY" -u "$GITHUB_ACTOR" --password-stdin
        else
            log_warning "GITHUB_TOKEN not set. You may need to login manually:"
            log_info "echo \$GITHUB_TOKEN | docker login $REGISTRY -u \$GITHUB_ACTOR --password-stdin"
        fi
    fi
    
    execute docker push "$FULL_IMAGE"
    log_success "Image pushed successfully: $FULL_IMAGE"
}

# Install CRDs and RBAC
install_crds() {
    log_info "Installing CRDs and RBAC..."
    
    cd "$OPERATOR_DIR"
    
    # Create namespace
    execute kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Install CRDs
    execute kubectl apply -f config/crd/bases/
    
    # Generate and apply RBAC
    cd config/rbac
    execute kubectl apply -f role.yaml
    execute kubectl apply -f role_binding.yaml
    execute kubectl apply -f service_account.yaml
    
    # Wait for CRDs to be established
    log_info "Waiting for CRDs to be established..."
    execute kubectl wait --for condition=established --timeout=60s crd/previewenvironments.preview.homecareapp.xyz
    
    log_success "CRDs and RBAC installed successfully"
}

# Deploy operator
deploy_operator() {
    log_info "Deploying operator to namespace: $NAMESPACE"
    
    cd "$OPERATOR_DIR"
    
    # Create operator deployment manifest
    cat > /tmp/operator-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: preview-operator-controller-manager
  namespace: $NAMESPACE
  labels:
    app.kubernetes.io/name: preview-operator
    app.kubernetes.io/instance: controller-manager
    app.kubernetes.io/component: manager
    app.kubernetes.io/managed-by: deploy-script
    control-plane: controller-manager
spec:
  replicas: 1
  selector:
    matchLabels:
      control-plane: controller-manager
  template:
    metadata:
      labels:
        control-plane: controller-manager
    spec:
      serviceAccountName: preview-operator-controller-manager
      containers:
      - name: manager
        image: $FULL_IMAGE
        imagePullPolicy: Always
        command:
        - /manager
        args:
        - --leader-elect
        env:
        - name: WATCH_NAMESPACE
          value: ""
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 500m
            memory: 128Mi
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8081
          initialDelaySeconds: 15
          periodSeconds: 20
        readinessProbe:
          httpGet:
            path: /readyz
            port: 8081
          initialDelaySeconds: 5
          periodSeconds: 10
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
      securityContext:
        runAsNonRoot: true
      terminationGracePeriodSeconds: 10
EOF
    
    execute kubectl apply -f /tmp/operator-deployment.yaml
    
    # Wait for deployment to be ready
    log_info "Waiting for operator deployment to be ready..."
    execute kubectl rollout status deployment/preview-operator-controller-manager -n "$NAMESPACE" --timeout=300s
    
    log_success "Operator deployed successfully"
}

# Check operator status
check_status() {
    log_info "Checking operator status..."
    
    echo
    log_info "Namespace: $NAMESPACE"
    kubectl get namespace "$NAMESPACE" 2>/dev/null || log_warning "Namespace not found"
    
    echo
    log_info "CRDs:"
    kubectl get crd | grep preview.homecareapp.xyz || log_warning "No preview CRDs found"
    
    echo
    log_info "Operator deployment:"
    kubectl get deployment -n "$NAMESPACE" || log_warning "No deployments found in namespace"
    
    echo
    log_info "Operator pods:"
    kubectl get pods -n "$NAMESPACE" || log_warning "No pods found in namespace"
    
    echo
    log_info "Preview environments:"
    kubectl get previewenvironments 2>/dev/null || log_warning "No preview environments found"
}

# Uninstall operator
uninstall_operator() {
    log_info "Uninstalling preview operator..."
    
    log_warning "This will delete all preview environments and related resources!"
    if [[ "$DRY_RUN" != "true" ]]; then
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborted"
            exit 0
        fi
    fi
    
    # Delete all preview environments first
    log_info "Deleting all preview environments..."
    execute kubectl delete previewenvironments --all 2>/dev/null || true
    
    # Delete operator deployment
    log_info "Deleting operator deployment..."
    execute kubectl delete deployment preview-operator-controller-manager -n "$NAMESPACE" 2>/dev/null || true
    
    # Delete RBAC
    log_info "Deleting RBAC resources..."
    execute kubectl delete clusterrolebinding preview-operator-manager-rolebinding 2>/dev/null || true
    execute kubectl delete clusterrole preview-operator-manager-role 2>/dev/null || true
    execute kubectl delete serviceaccount preview-operator-controller-manager -n "$NAMESPACE" 2>/dev/null || true
    
    # Delete CRDs
    log_info "Deleting CRDs..."
    execute kubectl delete crd previewenvironments.preview.homecareapp.xyz 2>/dev/null || true
    
    # Delete namespace
    log_info "Deleting namespace..."
    execute kubectl delete namespace "$NAMESPACE" 2>/dev/null || true
    
    log_success "Operator uninstalled successfully"
}

# Main execution
main() {
    log_info "Preview Environment Operator Deployment"
    log_info "Command: $COMMAND"
    log_info "Environment: $ENVIRONMENT"
    log_info "Image: $FULL_IMAGE"
    log_info "Namespace: $NAMESPACE"
    
    case "$COMMAND" in
        build)
            check_prerequisites
            build_image
            ;;
        push)
            check_prerequisites
            build_image
            push_image
            ;;
        deploy)
            check_prerequisites
            build_image
            push_image
            install_crds
            deploy_operator
            check_status
            ;;
        install)
            check_prerequisites
            install_crds
            ;;
        status)
            check_status
            ;;
        uninstall)
            uninstall_operator
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            show_help
            exit 1
            ;;
    esac
    
    log_success "Operation completed successfully!"
}

# Run main function
main "$@"