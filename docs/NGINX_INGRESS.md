# NGINX Ingress Controller Setup

This document explains how to install and manage NGINX Ingress Controller for the HomeCare application on Azure AKS.

## Overview

NGINX Ingress Controller replaces Azure Application Gateway to provide cost-effective ingress management with a Basic Load Balancer, reducing monthly costs by ~80-90%.

## Prerequisites

Before installing NGINX Ingress Controller, ensure you have:

1. **Azure CLI** installed and logged in (`az login`)
2. **kubectl** installed and configured
3. **Helm** installed (for package management)
4. **AKS cluster** running (deployed via Terraform)
5. **Proper permissions** to deploy to the cluster

## Installation

### Automated Installation (Recommended)

Use the provided installation script:

```bash
# Navigate to the scripts directory
cd scripts

# Run the installation script
./install-nginx-ingress.sh
```

The script will:
- Check all prerequisites
- Get AKS cluster credentials
- Install NGINX Ingress Controller via Helm
- Configure cost-optimized settings
- Wait for LoadBalancer IP assignment
- Display configuration instructions

### Manual Installation

If you prefer manual installation:

```bash
# Get AKS credentials
az aks get-credentials --resource-group homecare-app --name homecare-app

# Add Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Create namespace
kubectl create namespace ingress-nginx

# Install with cost-optimized configuration
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.replicaCount=1 \
  --set controller.resources.requests.cpu=100m \
  --set controller.resources.requests.memory=128Mi \
  --set controller.resources.limits.cpu=200m \
  --set controller.resources.limits.memory=256Mi \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-sku"=basic \
  --set controller.admissionWebhooks.enabled=false \
  --set defaultBackend.enabled=true \
  --timeout 600s \
  --wait
```

## Configuration

### Cost Optimization Features

The installation includes several cost optimizations:

- **Single replica** deployment
- **Basic Load Balancer** (instead of Standard)
- **Minimal resource requests** (100m CPU, 128Mi memory)
- **Disabled admission webhooks** (reduces complexity)
- **Optimized worker settings**

### Azure-Specific Settings

- Uses Azure Basic Load Balancer SKU
- Configured health probe path for Azure compatibility
- Optimized for single-node AKS clusters

## Management

### Using the Management Script

Use the provided management script for common operations:

```bash
# Show status
./scripts/manage-nginx-ingress.sh status

# Get LoadBalancer IP
./scripts/manage-nginx-ingress.sh ip

# Show DNS configuration
./scripts/manage-nginx-ingress.sh dns

# View logs
./scripts/manage-nginx-ingress.sh logs

# Restart controller
./scripts/manage-nginx-ingress.sh restart

# Test installation
./scripts/manage-nginx-ingress.sh test

# Uninstall
./scripts/manage-nginx-ingress.sh uninstall
```

### Manual Commands

```bash
# Check status
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Get LoadBalancer IP
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# View logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller -f

# Restart
kubectl rollout restart deployment -n ingress-nginx ingress-nginx-controller
```

## DNS Configuration

After installation, you need to configure DNS records:

1. **Get the LoadBalancer IP:**
   ```bash
   ./scripts/manage-nginx-ingress.sh ip
   ```

2. **Add DNS records** to your DNS provider:
   ```
   *.homecareapp.xyz  A  <LOADBALANCER_IP>
   homecareapp.xyz    A  <LOADBALANCER_IP>
   ```

3. **Verify DNS propagation:**
   ```bash
   nslookup homecareapp.xyz
   nslookup dev.homecareapp.xyz
   ```

## Application Deployment

Your Kubernetes ingress resources are already configured to use NGINX Ingress Controller:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: homecare-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: homecareapp.xyz  # or dev.homecareapp.xyz
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: homecare-service
            port:
              number: 80
```

Deploy your application using the existing Kustomize configuration:

```bash
# Development
kubectl apply -k k8s/overlays/dev

# Production  
kubectl apply -k k8s/overlays/prod
```

## Troubleshooting

### LoadBalancer IP Pending

If the LoadBalancer IP remains pending:

```bash
# Check service events
kubectl describe svc -n ingress-nginx ingress-nginx-controller

# Check Azure Load Balancer creation
az network lb list --resource-group MC_homecare-app_homecare-app_centralindia
```

### Pod Not Starting

If the controller pod doesn't start:

```bash
# Check pod events
kubectl describe pod -n ingress-nginx -l app.kubernetes.io/component=controller

# Check logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

### Ingress Not Working

If your application ingress doesn't work:

```bash
# Check ingress resources
kubectl get ingress -A

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller | grep ERROR

# Verify ingress class
kubectl get ingressclass
```

## Cost Comparison

| Component | Application Gateway | NGINX Ingress + Basic LB |
|-----------|-------------------|--------------------------|
| Application Gateway | ~$85/month | $0 |
| Load Balancer | Standard (~$20/month) | Basic (~$5/month) |
| **Total** | **~$105/month** | **~$5/month** |
| **Savings** | - | **~$100/month (95%)** |

## Security Considerations

- Basic Load Balancer has no built-in DDoS protection (unlike Standard LB)
- NGINX Ingress provides application-level security features
- Consider enabling Azure DDoS Protection if needed
- Use proper ingress annotations for security headers

## Monitoring

Monitor NGINX Ingress Controller:

```bash
# Pod metrics
kubectl top pods -n ingress-nginx

# Service endpoints
kubectl get endpoints -n ingress-nginx

# Ingress controller metrics (if enabled)
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller-metrics 8080:10254
curl http://localhost:8080/metrics
```

## Backup and Recovery

### Backup Configuration

```bash
# Export Helm values
helm get values ingress-nginx -n ingress-nginx > nginx-ingress-backup.yaml

# Backup ingress resources
kubectl get ingress -A -o yaml > ingress-backup.yaml
```

### Recovery

```bash
# Reinstall from backup
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --values nginx-ingress-backup.yaml

# Restore ingress resources
kubectl apply -f ingress-backup.yaml
```

## Additional Resources

- [NGINX Ingress Controller Documentation](https://kubernetes.github.io/ingress-nginx/)
- [Azure Load Balancer Documentation](https://docs.microsoft.com/en-us/azure/load-balancer/)
- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
