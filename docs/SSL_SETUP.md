# SSL Certificate Setup with Let's Encrypt

This document explains how SSL certificates are automatically provisioned and managed using cert-manager and Let's Encrypt in the HomeCare application.

## Overview

The HomeCare application uses:
- **cert-manager**: Kubernetes controller that manages SSL certificates
- **Let's Encrypt**: Free SSL certificate authority
- **NGINX Ingress Controller**: Routes traffic and terminates SSL

## Installation

SSL certificates are automatically configured when you run the NGINX Ingress installation script:

```bash
./scripts/install-nginx-ingress.sh
```

This script installs:
1. NGINX Ingress Controller
2. cert-manager (for certificate management)
3. Let's Encrypt ClusterIssuers (production and staging)

## Configuration

### Environment Variables

You can customize the Let's Encrypt email address:

```bash
export LETSENCRYPT_EMAIL="your-email@example.com"
./scripts/install-nginx-ingress.sh
```

If not set, defaults to `admin@homecareapp.xyz`.

### ClusterIssuers

Two ClusterIssuers are created:

#### Production Issuer (`letsencrypt-prod`)
- Used for production domains
- Issues trusted certificates
- Subject to rate limits (50 certificates per week per domain)
- Used by: Production environment

#### Staging Issuer (`letsencrypt-staging`)
- Used for testing and development
- Issues test certificates (not trusted by browsers)
- Higher rate limits for testing
- Used by: Development environment

## Ingress Configuration

### Base Configuration

The base ingress includes SSL settings that apply to all environments:

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - homecareapp.xyz
    secretName: homecare-tls
```

### Environment-Specific Overrides

#### Development Environment
- Uses `letsencrypt-staging` ClusterIssuer
- Domain: `dev.homecareapp.xyz`
- Certificate stored in: `homecare-dev-tls` secret

#### Production Environment
- Uses `letsencrypt-prod` ClusterIssuer
- Domain: `homecareapp.xyz`
- Certificate stored in: `homecare-prod-tls` secret

## DNS Requirements

Before certificates can be issued, ensure your DNS records point to the LoadBalancer IP:

```
homecareapp.xyz      A    <LOADBALANCER_IP>
*.homecareapp.xyz    A    <LOADBALANCER_IP>
```

Get the LoadBalancer IP:
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

## Certificate Lifecycle

### Automatic Provisioning
1. When you deploy an ingress with cert-manager annotations, cert-manager detects it
2. A Certificate resource is automatically created
3. cert-manager requests a certificate from Let's Encrypt
4. Let's Encrypt validates domain ownership via HTTP-01 challenge
5. Certificate is stored in the specified Kubernetes secret
6. NGINX Ingress uses the certificate for SSL termination

### Automatic Renewal
- Certificates are automatically renewed before expiration (typically 30 days before)
- No manual intervention required
- Zero-downtime renewals

## Monitoring and Troubleshooting

### Check Certificate Status

```bash
# List all certificates
kubectl get certificates --all-namespaces

# Check specific certificate details
kubectl describe certificate homecare-tls -n default

# Check certificate events
kubectl get events --field-selector involvedObject.kind=Certificate
```

### Check ClusterIssuers

```bash
# List ClusterIssuers
kubectl get clusterissuers

# Check ClusterIssuer status
kubectl describe clusterissuer letsencrypt-prod
```

### Check Certificate Secrets

```bash
# List TLS secrets
kubectl get secrets | grep tls

# Check certificate details in secret
kubectl get secret homecare-tls -o yaml
```

### Common Issues

#### Certificate Pending
If a certificate stays in "Pending" state:

1. Check DNS resolution:
   ```bash
   nslookup homecareapp.xyz
   ```

2. Check cert-manager logs:
   ```bash
   kubectl logs -n cert-manager deployment/cert-manager
   ```

3. Check ACME challenge:
   ```bash
   kubectl get challenges
   kubectl describe challenge <challenge-name>
   ```

#### Rate Limiting
If you hit Let's Encrypt rate limits:

1. Switch to staging issuer temporarily:
   ```yaml
   cert-manager.io/cluster-issuer: "letsencrypt-staging"
   ```

2. Wait for rate limit reset (weekly)

3. Switch back to production issuer

## Security Best Practices

### SSL Configuration
- All traffic is redirected to HTTPS
- TLS 1.2+ is enforced by NGINX Ingress
- Perfect Forward Secrecy is enabled

### Certificate Storage
- Private keys are stored securely in Kubernetes secrets
- Secrets are automatically managed by cert-manager
- No manual certificate handling required

## Backup and Recovery

### Certificate Backup
Certificates are automatically backed up with your Kubernetes cluster backup. For manual backup:

```bash
# Backup certificate secret
kubectl get secret homecare-tls -o yaml > homecare-tls-backup.yaml
```

### Recovery
If certificates are lost, they will be automatically re-provisioned when you redeploy the ingress resources.

## Cost Considerations

- Let's Encrypt certificates are **free**
- No additional costs for cert-manager
- Minimal resource overhead (~50Mi memory for cert-manager)

## Monitoring

### Certificate Expiration
Monitor certificate expiration with:

```bash
# Check certificate expiration dates
kubectl get certificates -o custom-columns=NAME:.metadata.name,READY:.status.conditions[0].status,SECRET:.spec.secretName,ISSUER:.spec.issuerRef.name,EXPIRATION:.status.notAfter
```

### Alerts
Consider setting up alerts for:
- Certificate expiration warnings
- Failed certificate renewals
- cert-manager pod failures

## Support

For issues related to:
- **cert-manager**: Check [cert-manager documentation](https://cert-manager.io/docs/)
- **Let's Encrypt**: Check [Let's Encrypt documentation](https://letsencrypt.org/docs/)
- **NGINX Ingress**: Check [NGINX Ingress documentation](https://kubernetes.github.io/ingress-nginx/)
