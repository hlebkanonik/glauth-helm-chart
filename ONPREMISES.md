# On-Premises Kubernetes Deployment Guide

This guide covers deploying GLAuth on on-premises Kubernetes clusters where cloud LoadBalancers are not available.

## Quick Start

### 1. Deploy with NodePort (Recommended)

```bash
# Deploy using on-premises configuration
helm install my-glauth ./glauth -f values-onpremises.yaml

# Get access information
kubectl get svc my-glauth
kubectl get nodes -o wide
```

### 2. Access the Services

**LDAP Access:**
```bash
# Get any node IP and use NodePort 30389
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
echo "LDAP: $NODE_IP:30389"

# Test connection
ldapsearch -H ldap://$NODE_IP:30389 \
  -D "cn=admin,dc=company,dc=local" \
  -w admin123 \
  -b "dc=company,dc=local" \
  "(objectClass=*)"
```

**API Access:**
```bash
# API is available on NodePort 30555
curl http://$NODE_IP:30555/api/v1/version
curl http://$NODE_IP:30555/internals/
```

## Deployment Options

### Option 1: NodePort Service (Default)

**Best for:** Development, testing, small production environments

```yaml
service:
  type: NodePort
  nodePorts:
    ldap: 30389
    api: 30555
```

**Pros:**
- ✅ Simple setup
- ✅ No additional infrastructure needed
- ✅ Works with any Kubernetes cluster

**Cons:**
- ❌ Requires knowing node IPs
- ❌ No load balancing across nodes
- ❌ Port conflicts possible

### Option 2: MetalLB Load Balancer

**Best for:** Production environments with bare metal clusters

1. Install MetalLB:
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
```

2. Configure IP pool:
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250  # Your available IP range
```

3. Deploy GLAuth:
```yaml
service:
  type: LoadBalancer  # MetalLB will handle this
```

### Option 3: External Load Balancer

**Best for:** Enterprise environments with existing load balancers

```yaml
service:
  type: ClusterIP  # Keep internal only
```

Configure your external load balancer (F5, HAProxy, etc.) to forward:
- `EXTERNAL_IP:3893` → `NODE_IP:30389`
- `EXTERNAL_IP:5555` → `NODE_IP:30555`

### Option 4: Port Forwarding

**Best for:** Development and testing

```bash
kubectl port-forward svc/my-glauth 3893:3893 5555:5555
```

## Security Considerations

### 1. Change Default Passwords

The on-premises configuration includes default users. **Change these immediately:**

```bash
# Generate new password hash
echo -n "your-new-password" | openssl dgst -sha256

# Update values-onpremises.yaml with new hash
```

### 2. Enable LDAPS (Production)

For production, enable LDAPS:

```yaml
appConfig: |
  [ldaps]
    enabled = true
    cert = "/app/certs/server.crt"
    key = "/app/certs/server.key"
```

### 3. Network Security

- Configure firewall rules to allow NodePorts (30000-32767)
- Use internal DNS names instead of IP addresses
- Consider VPN access for external users

### 4. Resource Limits

Adjust resource limits based on your environment:

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

## Troubleshooting

### Common Issues

1. **NodePort not accessible:**
   ```bash
   # Check if port is open
   telnet NODE_IP 30389
   
   # Check firewall
   sudo iptables -L -n | grep 30389
   ```

2. **Service not starting:**
   ```bash
   # Check pod status
   kubectl get pods -l app.kubernetes.io/name=glauth
   
   # Check logs
   kubectl logs -l app.kubernetes.io/name=glauth
   ```

3. **LDAP connection refused:**
   ```bash
   # Test from within cluster
   kubectl run ldap-test --image=openldap:2.4 --rm -it --restart=Never -- \
     ldapsearch -H ldap://my-glauth:3893 -D "cn=admin,dc=company,dc=local" -w admin123 -b "dc=company,dc=local"
   ```

### Network Diagnostics

```bash
# Check service endpoints
kubectl get endpoints my-glauth

# Check service configuration
kubectl get svc my-glauth -o yaml

# Test connectivity from different nodes
kubectl run netcat --image=busybox --rm -it --restart=Never -- \
  nc -zv my-glauth 3893
```

## Monitoring

### Health Checks

```bash
# Check API health
curl http://NODE_IP:30555/api/v1/version

# Check stats dashboard
curl http://NODE_IP:30555/internals/
```

### Logs

```bash
# Follow logs
kubectl logs -f -l app.kubernetes.io/name=glauth

# Check previous logs
kubectl logs --previous -l app.kubernetes.io/name=glauth
```

## Backup and Recovery

### Configuration Backup

```bash
# Backup ConfigMap
kubectl get configmap my-glauth-config -o yaml > glauth-config-backup.yaml

# Backup values
helm get values my-glauth > glauth-values-backup.yaml
```

### Restore

```bash
# Restore from backup
kubectl apply -f glauth-config-backup.yaml
helm upgrade my-glauth ./glauth -f glauth-values-backup.yaml
```

## Support

For issues specific to on-premises deployments:

1. Check the troubleshooting section above
2. Verify network connectivity and firewall rules
3. Ensure NodePorts are not conflicting with other services
4. Consider using MetalLB for better load balancing 