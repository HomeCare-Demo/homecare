# Alternative: NGINX Ingress Configuration

**Note**: The default setup uses Application Gateway Ingress Controller (AGIC). If you prefer NGINX Ingress Controller instead, follow these instructions:

## Why Consider NGINX Instead of AGIC?

- **Lower Cost**: No Application Gateway charges (~$20-30/month savings)
- **Simpler Setup**: Faster deployment without Application Gateway provisioning
- **More Control**: Direct control over ingress configuration

## Install NGINX Ingress Controller

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

# Wait for the controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Get the external IP of the LoadBalancer
kubectl get service ingress-nginx-controller -n ingress-nginx
```

## Base Ingress Configuration

Replace the content of `k8s/base/ingress.yaml` with:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: homecare-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
spec:
  rules:
  - host: homecareapp.xyz
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

## Dev Environment Patch

Update `k8s/overlays/dev/ingress-patch.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: homecare-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - host: dev.homecareapp.xyz
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

## Production Environment Patch

Update `k8s/overlays/prod/ingress-patch.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: homecare-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - homecareapp.xyz
    secretName: homecare-tls
  rules:
  - host: homecareapp.xyz
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

## SSL Certificate Setup with cert-manager

For production SSL certificates:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# Create ClusterIssuer for Let's Encrypt
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

## DNS Configuration for NGINX

After deploying NGINX Ingress Controller:

```bash
# Get the external IP of the NGINX ingress controller
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Configure DNS records to point to this IP
# *.homecareapp.xyz  A  <NGINX_EXTERNAL_IP>
# homecareapp.xyz    A  <NGINX_EXTERNAL_IP>
```

## Migration from AGIC to NGINX

If you want to switch from AGIC to NGINX:

1. **Disable AGIC addon**:
   ```bash
   az aks disable-addons --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --addons ingress-appgw
   ```

2. **Install NGINX** (using commands above)

3. **Update ingress configurations** with the NGINX versions provided

4. **Update DNS** to point to NGINX LoadBalancer IP instead of Application Gateway IP

## Benefits Comparison

### Application Gateway (Current Default)
- ✅ Native Azure integration and support
- ✅ Built-in SSL termination and WAF capabilities
- ✅ No additional pods in cluster
- ❌ Higher cost (~$20-30/month)
- ❌ Longer provisioning time

### NGINX Ingress Controller  
- ✅ Lower cost (only VM costs)
- ✅ Faster deployment
- ✅ More community support and flexibility
- ❌ Requires cluster resources
- ❌ Manual SSL certificate management
- ✅ Web Application Firewall (WAF)
- ✅ Better cost optimization on Azure

### NGINX Ingress Controller
- ✅ More flexible configuration
- ✅ Better community support
- ✅ Works across cloud providers
- ✅ More features and plugins
