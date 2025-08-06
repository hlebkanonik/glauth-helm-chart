# GLAuth Helm Chart

A lightweight Helm chart for deploying [GLAuth](https://github.com/glauth/glauth) LDAP server on Kubernetes.

## Introduction

GLAuth is a secure, fast and memory-efficient LDAP server. It's written in Go and provides a simple way to set up an LDAP server for authentication and directory services.

**⚠️ CRUCIAL: This is a lightweight Helm chart designed for testing purposes only.**

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

## Installing the Chart

To install the chart with the release name `my-glauth`:

```bash
helm install my-glauth ./glauth
```

## Configuration

The following table lists the configurable parameters of the glauth chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of GLAuth replicas | `1` |
| `image.repository` | GLAuth image repository | `glauth/glauth` |
| `image.tag` | GLAuth image tag | `v2.3.2` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `service.type` | Kubernetes service type | `NodePort` |
| `service.ldapPort` | LDAP service port | `3893` |
| `service.apiPort` | API service port | `5555` |
| `service.nodePorts.ldap` | LDAP NodePort | `30389` |
| `service.nodePorts.api` | API NodePort | `30555` |
| `appConfig` | Raw GLAuth configuration | See values.yaml |

### LDAP Configuration

The chart uses a simple `appConfig` field that contains the raw GLAuth configuration. You can customize the configuration by modifying the `appConfig` section in `values.yaml`:

```yaml
appConfig: |
  [ldap]
    enabled = true
    listen = "0.0.0.0:3893"

  [ldaps]
    enabled = false

  [api]
    enabled = true
    internals = true
    tls = false
    listen = "0.0.0.0:5555"

  [backend]
    datastore = "config"
    baseDN = "dc=example,dc=com"

  [[users]]
    name = "tesla"
    sn = "Tesla"
    mail = "tesla@example.com"
    uidnumber = 5001
    primarygroup = 5501
    loginShell = "/bin/bash"
    homeDir = "/home/user"
    passsha256 = "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"

  [[groups]]
    name = "users"
    gidnumber = 5501
```

## Usage

### 1. In-Cluster Testing (from within Kubernetes)

For testing from other pods or services within the same cluster:

```bash
# Service DNS names (k8s DNS format)
LDAP: my-glauth.default.svc.cluster.local:3893
API: my-glauth.default.svc.cluster.local:5555

# Test LDAP from within cluster
kubectl run ldap-test --image=openldap:2.4 --rm -it --restart=Never -- \
  ldapsearch -H ldap://my-glauth.default.svc.cluster.local:3893 \
  -D "cn=tesla,dc=example,dc=com" \
  -w password \
  -b "dc=example,dc=com" \
  "(objectClass=*)"

# Test API from within cluster
kubectl run api-test --image=curlimages/curl --rm -it --restart=Never -- \
  curl http://my-glauth.default.svc.cluster.local:5555/api/v1/version
```

### 2. NodePort Testing (external access)

For testing from outside the cluster:

```bash
# Get node IP and NodePorts
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
NODE_PORT_LDAP=$(kubectl get svc my-glauth -o jsonpath='{.spec.ports[0].nodePort}')
NODE_PORT_API=$(kubectl get svc my-glauth -o jsonpath='{.spec.ports[1].nodePort}')

echo "LDAP: $NODE_IP:$NODE_PORT_LDAP"
echo "API: $NODE_IP:$NODE_PORT_API"

# Test LDAP connection
ldapsearch -H ldap://$NODE_IP:$NODE_PORT_LDAP \
  -D "cn=tesla,dc=example,dc=com" \
  -w password \
  -b "dc=example,dc=com" \
  "(objectClass=*)"

# Test API
curl http://$NODE_IP:$NODE_PORT_API/api/v1/version
```

### 3. Port Forwarding (development/testing)

For quick local testing:

```bash
# Port forward to access the service locally
kubectl port-forward svc/my-glauth 3893:3893 5555:5555

# Test LDAP connection
ldapsearch -H ldap://localhost:3893 \
  -D "cn=tesla,dc=example,dc=com" \
  -w password \
  -b "dc=example,dc=com" \
  "(objectClass=*)"

# Test API
curl http://localhost:5555/api/v1/version
```

### Accessing Stats Dashboard

GLAuth provides a built-in stats dashboard for monitoring runtime metrics:

```bash
# 1. In-cluster access
curl http://my-glauth.default.svc.cluster.local:5555/internals/

# 2. NodePort access (external)
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
NODE_PORT_API=$(kubectl get svc my-glauth -o jsonpath='{.spec.ports[1].nodePort}')
curl http://$NODE_IP:$NODE_PORT_API/internals/

# 3. Port forwarding (local development)
kubectl port-forward svc/my-glauth 5555:5555
curl http://localhost:5555/internals/
```

The stats dashboard shows:
- Heap memory usage (global and detailed)
- Live objects in heap
- Live bytes in heap
- Runtime metrics over time

### Default Users

The chart includes two default users:
- **tesla** (Password: password)
- **einstein** (Password: password)

### Using with Applications

Configure your applications to use the GLAuth LDAP server:

```yaml
# Example application configuration
ldap:
  host: my-glauth
  port: 3893
  baseDN: "dc=example,dc=com"
  bindDN: "cn=tesla,dc=example,dc=com"
  bindPassword: "password"
```

## Security

- The default configuration uses plain LDAP (not LDAPS)
- Passwords are stored as SHA256 hashes
- Consider enabling TLS/SSL for production use
- Review and customize the security settings in the configuration

### Password Generation

To generate SHA256 hashes for passwords:

```bash
# Using OpenSSL
echo -n "yourpassword" | openssl dgst -sha256

# Using Python
python3 -c "import hashlib; print(hashlib.sha256('yourpassword'.encode()).hexdigest())"
```

## Troubleshooting

### Common Issues

1. **Pod not starting**: Check the ConfigMap configuration
2. **LDAP connection refused**: Verify service ports and network policies
3. **Authentication failures**: Check user credentials and base DN

### NodePort Access Issues (On-Premises)

If you can't access the service via NodePort:

```bash
# Check if NodePorts are assigned
kubectl get svc my-glauth -o jsonpath='{.spec.ports[0].nodePort}'
kubectl get svc my-glauth -o jsonpath='{.spec.ports[1].nodePort}'

# Verify firewall rules allow NodePort range (30000-32767)
# On Linux nodes:
sudo iptables -L -n | grep 30389

# Test connectivity from a node
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
telnet $NODE_IP 30389
```

### In-Cluster Access Issues

If you can't access the service from within the cluster:

```bash
# Check if service is running
kubectl get svc my-glauth

# Test from within cluster
kubectl run test-pod --image=busybox --rm -it --restart=Never -- \
  wget -O- http://my-glauth.default.svc.cluster.local:5555/api/v1/version

# Check DNS resolution
kubectl run dns-test --image=busybox --rm -it --restart=Never -- \
  nslookup my-glauth.default.svc.cluster.local
```

### Debugging

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=glauth

# View logs
kubectl logs -l app.kubernetes.io/name=glauth

# Check ConfigMap
kubectl get configmap my-glauth-config -o yaml

# Test connectivity
kubectl run ldap-test --image=openldap:2.4 --rm -it --restart=Never -- \
  ldapsearch -H ldap://my-glauth:3893 -D "cn=tesla,dc=example,dc=com" -w password -b "dc=example,dc=com" "(objectClass=*)"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the chart
5. Submit a pull request

## License

This chart is licensed under the same license as GLAuth. 