#!/bin/bash

# NGINX Ingress Controller Installation Script for HomeCare AKS Cluster
# This script installs NGINX Ingress Controller with cost-optimized settings
# for a single-node AKS cluster using Basic Load Balancer

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="ingress-nginx"
RELEASE_NAME="ingress-nginx"
CHART_VERSION="4.8.3"
TIMEOUT="600s"

# Resource group and cluster name (update these to match your setup)
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-homecare-app}"
CLUSTER_NAME="${AZURE_CLUSTER_NAME:-homecare-app}"

echo -e "${BLUE}🚀 HomeCare NGINX Ingress Controller Installation${NC}"
echo -e "${BLUE}=================================================${NC}"

# Function to print status messages
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check prerequisites
echo -e "\n${BLUE}Checking prerequisites...${NC}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi
print_status "kubectl is installed"

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    print_error "helm is not installed. Please install helm first."
    echo -e "${YELLOW}Install Helm:${NC}"
    echo "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    exit 1
fi
print_status "helm is installed"

# Check if az CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install Azure CLI first."
    exit 1
fi
print_status "Azure CLI is installed"

# Check if logged into Azure
if ! az account show &> /dev/null; then
    print_error "Not logged into Azure. Please run 'az login' first."
    exit 1
fi
print_status "Logged into Azure"

# Get AKS credentials
echo -e "\n${BLUE}Getting AKS cluster credentials...${NC}"
az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --overwrite-existing
print_status "AKS credentials configured"

# Check cluster connectivity
echo -e "\n${BLUE}Testing cluster connectivity...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi
print_status "Connected to Kubernetes cluster"

# Show cluster info
echo -e "\n${BLUE}Getting cluster information...${NC}"
if ! CLUSTER_VERSION=$(kubectl version --client=false --output=yaml 2>/dev/null | grep 'gitVersion:' | head -1 | awk '{print $2}'); then
    CLUSTER_VERSION="Unable to determine"
fi
if ! NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' '); then
    NODE_COUNT="0"
fi
print_info "Cluster version: ${CLUSTER_VERSION}"
print_info "Node count: ${NODE_COUNT}"

# Verify we have at least one node
if [ "$NODE_COUNT" = "0" ]; then
    print_warning "No nodes found in cluster. This might indicate a connectivity issue."
fi

# Check if NGINX Ingress is already installed
echo -e "\n${BLUE}Checking for existing NGINX Ingress installation...${NC}"
if helm list -n "${NAMESPACE}" | grep -q "${RELEASE_NAME}"; then
    print_warning "NGINX Ingress Controller is already installed"
    
    read -p "Do you want to upgrade it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_MODE="upgrade"
    else
        print_info "Skipping installation"
        exit 0
    fi
else
    INSTALL_MODE="install"
fi

# Add NGINX Ingress Helm repository
echo -e "\n${BLUE}Adding NGINX Ingress Helm repository...${NC}"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
print_status "Helm repository added and updated"

# Create namespace
echo -e "\n${BLUE}Creating namespace...${NC}"
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
print_status "Namespace '${NAMESPACE}' ready"

# Prepare values for cost-optimized installation
echo -e "\n${BLUE}Preparing NGINX Ingress configuration...${NC}"
cat > /tmp/nginx-ingress-values.yaml << EOF
controller:
  # Service configuration for Azure Basic Load Balancer
  service:
    type: LoadBalancer
    loadBalancerSourceRanges: []
    annotations:
      service.beta.kubernetes.io/azure-load-balancer-sku: "basic"
      service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: "/healthz"
  
  # Resource optimization for single node cluster
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 128Mi
  
  # Single replica for cost optimization
  replicaCount: 1
  
  # Node selector for single node (optional)
  # nodeSelector:
  #   kubernetes.io/os: linux
  
  # Disable admission webhooks for simplicity and resource savings
  admissionWebhooks:
    enabled: false
  
  # Enable metrics for monitoring (lightweight)
  metrics:
    enabled: true
    serviceMonitor:
      enabled: false
  
  # Performance and compatibility settings
  config:
    use-forwarded-headers: "true"
    compute-full-forwarded-for: "true"
    use-proxy-protocol: "false"
    # Enable gzip compression
    enable-gzip: "true"
    # Set worker processes
    worker-processes: "1"
    # Set worker connections
    worker-connections: "1024"

# Default backend - disabled for ARM64 compatibility
# The default backend has architecture compatibility issues on ARM64
# NGINX Ingress Controller works fine without it for basic use cases
defaultBackend:
  enabled: false

# Resource usage optimization
rbac:
  create: true

serviceAccount:
  create: true
EOF

print_status "Configuration prepared"

# Install or upgrade NGINX Ingress Controller
if [ "${INSTALL_MODE}" = "install" ]; then
    echo -e "\n${BLUE}Installing NGINX Ingress Controller...${NC}"
elif [ "${INSTALL_MODE}" = "upgrade" ]; then
    echo -e "\n${BLUE}Upgrading NGINX Ingress Controller...${NC}"
fi

if [ "${INSTALL_MODE}" = "install" ]; then
    helm install "${RELEASE_NAME}" ingress-nginx/ingress-nginx \
        --namespace "${NAMESPACE}" \
        --version "${CHART_VERSION}" \
        --values /tmp/nginx-ingress-values.yaml \
        --timeout "${TIMEOUT}" \
        --wait
else
    helm upgrade "${RELEASE_NAME}" ingress-nginx/ingress-nginx \
        --namespace "${NAMESPACE}" \
        --version "${CHART_VERSION}" \
        --values /tmp/nginx-ingress-values.yaml \
        --timeout "${TIMEOUT}" \
        --wait
fi

print_status "NGINX Ingress Controller ${INSTALL_MODE}ed successfully"

# Wait for LoadBalancer to get external IP
echo -e "\n${BLUE}Waiting for LoadBalancer to get external IP...${NC}"
print_info "This may take 2-5 minutes..."

EXTERNAL_IP=""
WAIT_COUNT=0
MAX_WAIT=60

while [ -z "$EXTERNAL_IP" ] && [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    EXTERNAL_IP=$(kubectl get svc -n "${NAMESPACE}" "${RELEASE_NAME}-controller" \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -z "$EXTERNAL_IP" ]; then
        echo -n "."
        sleep 5
        ((WAIT_COUNT++))
    fi
done

echo

if [ -n "$EXTERNAL_IP" ]; then
    print_status "LoadBalancer external IP assigned: ${EXTERNAL_IP}"
else
    print_warning "LoadBalancer external IP not yet assigned (this is normal)"
    print_info "Check the IP later with: kubectl get svc -n ${NAMESPACE} ${RELEASE_NAME}-controller"
fi

# Clean up temporary files
rm -f /tmp/nginx-ingress-values.yaml

# Display installation summary
echo -e "\n${GREEN}🎉 Installation Summary${NC}"
echo -e "${GREEN}======================${NC}"
print_status "NGINX Ingress Controller is running"
print_status "Namespace: ${NAMESPACE}"
print_status "Release: ${RELEASE_NAME}"
print_status "Chart Version: ${CHART_VERSION}"

if [ -n "$EXTERNAL_IP" ]; then
    print_status "LoadBalancer IP: ${EXTERNAL_IP}"
else
    print_info "LoadBalancer IP: Pending (check with command below)"
fi

echo -e "\n${BLUE}Next Steps:${NC}"
echo -e "1. ${YELLOW}Get the LoadBalancer IP:${NC}"
echo -e "   kubectl get svc -n ${NAMESPACE} ${RELEASE_NAME}-controller"
echo
echo -e "2. ${YELLOW}Update your DNS records:${NC}"
if [ -n "$EXTERNAL_IP" ]; then
    echo -e "   *.homecareapp.xyz  A  ${EXTERNAL_IP}"
    echo -e "   homecareapp.xyz    A  ${EXTERNAL_IP}"
else
    echo -e "   *.homecareapp.xyz  A  <EXTERNAL_IP>"
    echo -e "   homecareapp.xyz    A  <EXTERNAL_IP>"
fi
echo
echo -e "3. ${YELLOW}Deploy your application:${NC}"
echo -e "   Your Kubernetes ingress resources should now work with NGINX Ingress Controller"
echo
echo -e "4. ${YELLOW}Test the installation:${NC}"
echo -e "   kubectl get pods -n ${NAMESPACE}"
echo -e "   kubectl get svc -n ${NAMESPACE}"

echo -e "\n${GREEN}✅ NGINX Ingress Controller installation completed!${NC}"
