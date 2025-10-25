# Kubernetes Deployment Guide

## Prerequisites

1. Kubernetes cluster (Minikube, Kind, or cloud provider)
2. kubectl configured
3. NGINX Ingress Controller installed
4. cert-manager installed (for TLS)

## Quick Install Prerequisites

### Install NGINX Ingress Controller
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

### Install cert-manager
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

## Deployment Steps

### 1. Create GHCR Secret (for private images)
```bash
# Option 1: Using the helper script
./create-secret.sh <GITHUB_USERNAME> <GITHUB_PAT> <EMAIL>
kubectl apply -f ghcr-secret-generated.yaml

# Option 2: Using kubectl directly
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<GITHUB_USERNAME> \
  --docker-password=<GITHUB_PAT> \
  --docker-email=<EMAIL>
```

### 2. Deploy the Application
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### 3. Verify Deployment
```bash
kubectl get pods
kubectl get svc wisecow
```

### 4. Setup TLS (Optional)
```bash
# Create cert-manager ClusterIssuer
kubectl apply -f cert-issuer.yaml

# Deploy Ingress with TLS
kubectl apply -f ingress.yaml
```

### 5. Configure DNS
Point `wisecow.suyashbhawsar.com` to your cluster's external IP:
```bash
kubectl get svc -n ingress-nginx
```

## Testing

### Without TLS (using LoadBalancer)
```bash
# Get external IP
kubectl get svc wisecow

# Test the application
curl http://<EXTERNAL-IP>
```

### With TLS (using Ingress)
```bash
# Check certificate status
kubectl get certificate
kubectl describe certificate wisecow-tls

# Test the application
curl https://wisecow.suyashbhawsar.com
```

## Updating the Application

```bash
# Update image version in deployment.yaml, then:
kubectl apply -f deployment.yaml

# Or use kubectl set image:
kubectl set image deployment/wisecow wisecow=ghcr.io/suyashbhawsar/wisecow:0.2.0
```

## Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/wisecow

# Check rollout history
kubectl rollout history deployment/wisecow
```

## Troubleshooting

### Check pod logs
```bash
kubectl logs -l app=wisecow
```

### Check pod status
```bash
kubectl describe pod -l app=wisecow
```

### Check certificate issues
```bash
kubectl describe certificate wisecow-tls
kubectl logs -n cert-manager -l app=cert-manager
```

## Cleanup

```bash
kubectl delete -f ingress.yaml
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete -f cert-issuer.yaml
```
