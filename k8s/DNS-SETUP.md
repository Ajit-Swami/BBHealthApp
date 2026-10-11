# DNS Setup for BBHealthApp with LoadBalancer

## Overview
This guide explains how to configure DNS for the BBHealthApp frontend using Kubernetes LoadBalancer with MetalLB.

## Architecture
- **Frontend Service**: LoadBalancer type with MetalLB
- **DNS Hostname**: bbhealthapp.local
- **LoadBalancer IP**: 192.168.1.240 (configurable)
- **Ingress**: Routes traffic based on hostname

## Setup Steps

### 1. Update MetalLB IP Range (On EC2)

The MetalLB configuration uses IP range `192.168.1.240-192.168.1.250`. You may need to adjust this based on your EC2 network:

```bash
# Check your EC2 instance's network
ip addr show

# If using a different network, update metallb-config.yaml:
# Change the addresses to match your network subnet
```

### 2. Configure DNS Options

#### Option A: Local /etc/hosts (For Testing)

On your local machine, add the LoadBalancer IP to your hosts file:

**Linux/Mac:**
```bash
# Get the LoadBalancer IP after deployment
kubectl get svc frontend -n bbhealthapp

# Add to /etc/hosts
echo "<LOADBALANCER-IP> bbhealthapp.local" | sudo tee -a /etc/hosts
```

**Windows:**
```
# Edit C:\Windows\System32\drivers\etc\hosts
# Add: <LOADBALANCER-IP> bbhealthapp.local
```

#### Option B: Cloud DNS (For Production)

If you have a domain, create an A record:

1. Go to your DNS provider (Route53, Cloudflare, GoDaddy, etc.)
2. Create an A record:
   - Name: `bbhealthapp` (or subdomain like `app`)
   - Type: A
   - Value: `<LOADBALANCER-IP>`
   - TTL: 300

#### Option C: nip.io (Free DNS Service)

Use nip.io to map your IP to a domain:

```bash
# Get EC2 public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Access via: http://<PUBLIC-IP>.nip.io
# Example: http://52.34.56.78.nip.io
```

Update ingress.yaml to use nip.io:
```yaml
spec:
  rules:
    - host: <PUBLIC-IP>.nip.io
```

### 3. Access the Application

After deployment:

```bash
# Get LoadBalancer IP
kubectl get svc frontend -n bbhealthapp

# Access via DNS
http://bbhealthapp.local

# Or directly via IP
http://<LOADBALANCER-IP>
```

### 4. Verify DNS Resolution

```bash
# Test DNS resolution
ping bbhealthapp.local

# Test HTTP access
curl http://bbhealthapp.local
```

### 5. Update EC2 Security Group

Ensure your EC2 security group allows:
- Port 80 (HTTP) from 0.0.0.0/0
- Port 443 (HTTPS) from 0.0.0.0/0
- Port 22 (SSH) from your IP

## Troubleshooting

### LoadBalancer stuck in Pending

```bash
# Check MetalLB pods
kubectl get pods -n metallb-system

# Check MetalLB logs
kubectl logs -n metallb-system -l app=metallb-controller

# Verify IP range matches your network
kubectl get configmap config -n metallb-system -o yaml
```

### DNS not resolving

```bash
# Check if LoadBalancer has IP
kubectl get svc frontend -n bbhealthapp

# Verify hosts file or DNS record
# Test with IP directly
curl http://<LOADBALANCER-IP>
```

### Ingress not working

```bash
# Check ingress controller
kubectl get pods -n ingress

# Check ingress rules
kubectl describe ingress bbhealthapp-ingress -n bbhealthapp

# Check if hostname matches
kubectl get ingress -n bbhealthapp
```

## MetalLB Configuration Notes

The `metallb-config.yaml` uses Layer 2 mode, which is suitable for single-node clusters like MicroK8s on EC2.

**Important:**
- The IP range must be within your EC2 instance's subnet
- Only one node can respond to ARP requests in Layer 2 mode
- For production multi-node clusters, consider BGP mode

## Production Recommendations

For production deployment:
1. Use a real domain name with proper DNS records
2. Enable SSL/TLS with cert-manager
3. Use a managed LoadBalancer (AWS ELB) if using EKS
4. Configure health checks and monitoring
5. Set up DNS failover if needed
