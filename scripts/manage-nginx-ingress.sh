#!/bin/bash

# NGINX Ingress Controller Management Script for HomeCare AKS Cluster
# This script provides utilities to manage NGINX Ingress Controller

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

show_help() {
    echo -e "${BLUE}NGINX Ingress Controller Management Script${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  status       Show NGINX Ingress Controller status"
    echo "  ip           Get LoadBalancer external IP"
    echo "  logs         Show controller logs"
    echo "  restart      Restart the controller"
    echo "  uninstall    Remove NGINX Ingress Controller"
    echo "  dns          Show DNS configuration"
    echo "  test         Test the installation"
    echo "  help         Show this help message"
    echo
}

check_prerequisites() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
}

show_status() {
    echo -e "${BLUE}NGINX Ingress Controller Status${NC}"
    echo -e "${BLUE}===============================${NC}"
    
    # Check if namespace exists
    if ! kubectl get namespace "${NAMESPACE}" &> /dev/null; then
        print_error "Namespace '${NAMESPACE}' not found"
        print_info "NGINX Ingress Controller is not installed"
        return 1
    fi
    
    # Check if Helm release exists
    if command -v helm &> /dev/null && helm list -n "${NAMESPACE}" | grep -q "${RELEASE_NAME}"; then
        HELM_STATUS=$(helm status "${RELEASE_NAME}" -n "${NAMESPACE}" -o json | jq -r '.info.status')
        print_status "Helm Release: ${RELEASE_NAME} (${HELM_STATUS})"
    else
        print_warning "Helm release not found (may be installed manually)"
    fi
    
    echo
    echo "Pods:"
    kubectl get pods -n "${NAMESPACE}" -o wide
    
    echo
    echo "Services:"
    kubectl get svc -n "${NAMESPACE}" -o wide
    
    echo
    echo "ConfigMaps:"
    kubectl get configmap -n "${NAMESPACE}"
}

get_external_ip() {
    echo -e "${BLUE}LoadBalancer External IP${NC}"
    echo -e "${BLUE}========================${NC}"
    
    EXTERNAL_IP=$(kubectl get svc -n "${NAMESPACE}" "${RELEASE_NAME}-controller" \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -n "$EXTERNAL_IP" ]; then
        print_status "External IP: ${EXTERNAL_IP}"
        echo
        echo -e "${YELLOW}Copy this IP for your DNS configuration:${NC}"
        echo -e "${GREEN}${EXTERNAL_IP}${NC}"
    else
        print_warning "External IP not yet assigned"
        print_info "LoadBalancer may still be provisioning"
        echo
        echo "Service details:"
        kubectl get svc -n "${NAMESPACE}" "${RELEASE_NAME}-controller" -o wide
    fi
}

show_logs() {
    echo -e "${BLUE}NGINX Ingress Controller Logs${NC}"
    echo -e "${BLUE}=============================${NC}"
    
    # Get the controller pod
    CONTROLLER_POD=$(kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$CONTROLLER_POD" ]; then
        print_status "Showing logs for pod: ${CONTROLLER_POD}"
        echo
        kubectl logs -n "${NAMESPACE}" "${CONTROLLER_POD}" --tail=50 -f
    else
        print_error "Controller pod not found"
    fi
}

restart_controller() {
    echo -e "${BLUE}Restarting NGINX Ingress Controller${NC}"
    echo -e "${BLUE}====================================${NC}"
    
    # Restart deployment
    kubectl rollout restart deployment -n "${NAMESPACE}" "${RELEASE_NAME}-controller"
    
    print_status "Restart initiated"
    print_info "Waiting for rollout to complete..."
    
    kubectl rollout status deployment -n "${NAMESPACE}" "${RELEASE_NAME}-controller" --timeout=300s
    
    print_status "Controller restarted successfully"
}

uninstall_controller() {
    echo -e "${YELLOW}⚠ WARNING: This will remove NGINX Ingress Controller${NC}"
    echo -e "${YELLOW}This will affect all applications using ingress resources!${NC}"
    echo
    
    read -p "Are you sure you want to uninstall? (type 'yes' to confirm): " -r
    if [ "$REPLY" != "yes" ]; then
        print_info "Uninstall cancelled"
        return 0
    fi
    
    echo -e "\n${BLUE}Uninstalling NGINX Ingress Controller${NC}"
    echo -e "${BLUE}=====================================${NC}"
    
    # Try Helm uninstall first
    if command -v helm &> /dev/null && helm list -n "${NAMESPACE}" | grep -q "${RELEASE_NAME}"; then
        print_info "Uninstalling Helm release..."
        helm uninstall "${RELEASE_NAME}" -n "${NAMESPACE}"
        print_status "Helm release uninstalled"
    else
        print_info "No Helm release found, removing resources manually..."
        kubectl delete all --all -n "${NAMESPACE}"
    fi
    
    # Remove namespace
    kubectl delete namespace "${NAMESPACE}" --ignore-not-found=true
    
    print_status "NGINX Ingress Controller uninstalled"
    print_warning "Don't forget to update your DNS records"
}

show_dns_config() {
    echo -e "${BLUE}DNS Configuration${NC}"
    echo -e "${BLUE}=================${NC}"
    
    EXTERNAL_IP=$(kubectl get svc -n "${NAMESPACE}" "${RELEASE_NAME}-controller" \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -n "$EXTERNAL_IP" ]; then
        echo -e "${GREEN}Current LoadBalancer IP: ${EXTERNAL_IP}${NC}"
        echo
        echo -e "${YELLOW}Add these DNS records to your DNS provider:${NC}"
        echo -e "*.homecareapp.xyz  A  ${EXTERNAL_IP}"
        echo -e "homecareapp.xyz    A  ${EXTERNAL_IP}"
    else
        print_warning "LoadBalancer IP not yet available"
        echo
        echo -e "${YELLOW}Once IP is available, add these DNS records:${NC}"
        echo -e "*.homecareapp.xyz  A  <EXTERNAL_IP>"
        echo -e "homecareapp.xyz    A  <EXTERNAL_IP>"
        echo
        echo -e "${BLUE}Get the IP with:${NC} $0 ip"
    fi
    
    echo
    echo -e "${BLUE}Verify DNS propagation:${NC}"
    echo -e "nslookup homecareapp.xyz"
    echo -e "nslookup dev.homecareapp.xyz"
}

test_installation() {
    echo -e "${BLUE}Testing NGINX Ingress Controller Installation${NC}"
    echo -e "${BLUE}=============================================${NC}"
    
    # Check namespace
    if kubectl get namespace "${NAMESPACE}" &> /dev/null; then
        print_status "Namespace '${NAMESPACE}' exists"
    else
        print_error "Namespace '${NAMESPACE}' not found"
        return 1
    fi
    
    # Check controller deployment
    if kubectl get deployment -n "${NAMESPACE}" "${RELEASE_NAME}-controller" &> /dev/null; then
        READY_REPLICAS=$(kubectl get deployment -n "${NAMESPACE}" "${RELEASE_NAME}-controller" -o jsonpath='{.status.readyReplicas}')
        DESIRED_REPLICAS=$(kubectl get deployment -n "${NAMESPACE}" "${RELEASE_NAME}-controller" -o jsonpath='{.spec.replicas}')
        
        if [ "$READY_REPLICAS" = "$DESIRED_REPLICAS" ]; then
            print_status "Controller deployment is ready (${READY_REPLICAS}/${DESIRED_REPLICAS})"
        else
            print_warning "Controller deployment not fully ready (${READY_REPLICAS:-0}/${DESIRED_REPLICAS})"
        fi
    else
        print_error "Controller deployment not found"
        return 1
    fi
    
    # Check service
    if kubectl get svc -n "${NAMESPACE}" "${RELEASE_NAME}-controller" &> /dev/null; then
        print_status "Controller service exists"
        
        SERVICE_TYPE=$(kubectl get svc -n "${NAMESPACE}" "${RELEASE_NAME}-controller" -o jsonpath='{.spec.type}')
        if [ "$SERVICE_TYPE" = "LoadBalancer" ]; then
            print_status "Service type is LoadBalancer"
            
            EXTERNAL_IP=$(kubectl get svc -n "${NAMESPACE}" "${RELEASE_NAME}-controller" \
                -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
            
            if [ -n "$EXTERNAL_IP" ]; then
                print_status "External IP assigned: ${EXTERNAL_IP}"
            else
                print_warning "External IP pending"
            fi
        else
            print_warning "Service type is not LoadBalancer: ${SERVICE_TYPE}"
        fi
    else
        print_error "Controller service not found"
        return 1
    fi
    
    # Test ingress class
    if kubectl get ingressclass nginx &> /dev/null; then
        print_status "IngressClass 'nginx' is available"
    else
        print_warning "IngressClass 'nginx' not found"
    fi
    
    echo
    print_status "NGINX Ingress Controller installation test completed"
}

# Main script logic
case "${1:-help}" in
    "status")
        check_prerequisites
        show_status
        ;;
    "ip")
        check_prerequisites
        get_external_ip
        ;;
    "logs")
        check_prerequisites
        show_logs
        ;;
    "restart")
        check_prerequisites
        restart_controller
        ;;
    "uninstall")
        check_prerequisites
        uninstall_controller
        ;;
    "dns")
        check_prerequisites
        show_dns_config
        ;;
    "test")
        check_prerequisites
        test_installation
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac
