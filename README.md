# GLAuth Helm Chart

A production-ready Helm chart for deploying [GLAuth](https://github.com/glauth/glauth) LDAP server on Kubernetes.

## Overview

**⚠️ CRUCIAL: This is a lightweight Helm chart designed for testing purposes only.**

GLAuth is a secure, fast and memory-efficient LDAP server written in Go. This Helm chart provides an easy way to deploy GLAuth on Kubernetes with:

- **Lightweight design**: Optimized for testing and development environments
- **ConfigMap-based configuration**: No need for persistent volumes or external databases
- **No persistent storage**: All configuration stored in ConfigMap, no PVC required
- **No external dependencies**: Self-contained without database requirements
- **Dual port support**: LDAP (3893) and API (5555) ports
- **Multiple environments**: Pre-configured values for development and production
- **Security features**: Configurable authentication and authorization

**⚠️ NOT RECOMMENDED FOR PRODUCTION**: This chart uses ConfigMap storage which means:
- Configuration changes require pod restart
- No data persistence across pod restarts
- Limited scalability for high-traffic environments
- No backup/restore capabilities for user data

For production use, consider using a proper LDAP server with persistent storage and external databases.

## Use Cases and Limitations

### ✅ Recommended Use Cases
- **Development environments**: Local testing and development
- **CI/CD pipelines**: Automated testing with LDAP authentication
- **Proof of concept**: Demonstrating LDAP integration
- **Learning and education**: Understanding LDAP concepts
- **Temporary testing**: Short-term testing scenarios
- **Demo environments**: Showcasing LDAP functionality

### ❌ Not Suitable For
- **Production environments**: No data persistence or backup capabilities
- **High-traffic applications**: Limited scalability and performance
- **Multi-user production systems**: No user data persistence
- **Enterprise deployments**: Missing enterprise features like clustering
- **Long-term data storage**: All data is ephemeral

### 🔧 Technical Limitations
- **ConfigMap storage**: Configuration changes require pod restart
- **No persistence**: Data lost on pod restart or deletion
- **Single instance**: No clustering or high availability
- **Memory-only**: No disk-based storage for user data
- **No backup**: No built-in backup/restore mechanisms

## Quick Start

### Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

### Basic Installation

```bash
# Clone the repository
git clone <repository-url>
cd glauth-helm-chart

# Install with default NodePort configuration
helm install my-glauth ./glauth

# Get access information
kubectl get svc my-glauth
kubectl get nodes -o wide
```

**Access Methods:**

1. **In-Cluster**: `my-glauth.default.svc.cluster.local:3893` (LDAP) and `:5555` (API)
2. **NodePort**: `NODE_IP:30389` (LDAP) and `NODE_IP:30555` (API)

### Cloud Installation

For cloud environments with LoadBalancer support:

```bash
# Create custom values file for cloud
cat > values-cloud.yaml << EOF
service:
  type: LoadBalancer
  ldapPort: 3893
  apiPort: 5555
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"  # For AWS
EOF

# Install with cloud configuration
helm install my-glauth ./glauth -f values-cloud.yaml
```

### Development Installation

```bash
# Install with development settings
helm install my-glauth-dev ./glauth -f glauth/values-dev.yaml
```

## Configuration

### Default Configuration (On-Premises)

The chart includes a default configuration optimized for on-premises environments:
- **Service Type**: NodePort (for external access without cloud LoadBalancer)
- **LDAP Port**: 3893 (NodePort: 30389)
- **API Port**: 5555 (NodePort: 30555)
- **Test Users**: `tesla` and `einstein` (password: `password`)
- **Base DN**: `dc=example,dc=com`

### Cloud Environment Configuration

For cloud environments, modify the service configuration:

```yaml
service:
  type: LoadBalancer  # Instead of NodePort
  ldapPort: 3893
  apiPort: 5555
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"  # For AWS
    # service.beta.kubernetes.io/azure-load-balancer-internal: "false"  # For Azure
    # service.beta.kubernetes.io/gce-load-balancer-type: "External"  # For GCP
```

### Customizing Configuration

You can customize the GLAuth configuration by modifying the `appConfig` section in your values file:

```yaml
appConfig: |
  [ldap]
    enabled = true
    listen = "0.0.0.0:3893"
  
  [api]
    enabled = true
    listen = "0.0.0.0:5555"
  
  [backend]
    baseDN = "dc=mycompany,dc=com"
  
  [[users]]
    name = "myuser"
    sn = "MyUser"
    mail = "myuser@company.com"
    uidnumber = 5001
    primarygroup = 5501
    passsha256 = "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"
  
  [[groups]]
    name = "users"
    gidnumber = 5501
```

### Environment-Specific Values

The chart includes pre-configured values for different environments:

- **`values.yaml`**: Default configuration for testing
- **`values-dev.yaml`**: Development environment with relaxed security
- **`values-production.yaml`**: Production environment with enhanced security

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

## Security Considerations

### Testing Environment Security

**⚠️ IMPORTANT**: This chart is designed for testing environments only. For production deployments, implement proper security measures.

### Production Deployment (Not Recommended)

For production deployments, consider:

1. **Enable TLS/SSL**: Set `config.ldaps.enabled: true`
2. **Use strong passwords**: Generate proper SHA256 hashes for user passwords
3. **Restrict API access**: Set `config.api.internals: false`
4. **Configure ingress with TLS**: Use proper certificates
5. **Set resource limits**: Configure appropriate CPU and memory limits
6. **Use persistent storage**: Implement proper data persistence
7. **Implement backup strategies**: Regular backup and recovery procedures

### Testing Environment Recommendations

For testing environments:

1. **Use default passwords**: The chart includes test users with known passwords
2. **Enable internals**: Keep `config.api.internals: true` for monitoring
3. **Minimal security**: Focus on functionality over security for testing
4. **Regular cleanup**: Delete and redeploy for fresh testing environments

### Password Generation

To generate SHA256 hashes for passwords:

```bash
# Using OpenSSL
echo -n "yourpassword" | openssl dgst -sha256

# Using Python
python3 -c "import hashlib; print(hashlib.sha256('yourpassword'.encode()).hexdigest())"
```

## Troubleshooting

**Note**: This chart is designed for testing purposes. If you encounter issues, consider redeploying for a fresh environment.

### Common Issues

1. **Pod not starting**: Check the ConfigMap configuration
2. **LDAP connection refused**: Verify service ports and network policies
3. **Authentication failures**: Check user credentials and base DN
4. **Data loss after restart**: This is expected behavior - data is not persistent

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

### LoadBalancer Issues (Cloud)

```bash
# Check LoadBalancer status
kubectl get svc my-glauth -o wide

# Check if external IP is assigned
kubectl get svc my-glauth -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Test connectivity
LB_IP=$(kubectl get svc my-glauth -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
telnet $LB_IP 3893
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

## Architecture

**Lightweight Testing Architecture**: This chart creates minimal Kubernetes resources optimized for testing scenarios.

The Helm chart creates the following Kubernetes resources:

- **ConfigMap**: Contains the GLAuth configuration file (no persistent storage)
- **Deployment**: Runs the GLAuth container with the config mounted (single instance)
- **Service**: Exposes LDAP and API ports (NodePort by default for on-premises)
- **ServiceAccount**: For pod authentication

**No Persistent Resources:**
- ❌ No PersistentVolumeClaims (PVC)
- ❌ No PersistentVolumes (PV)
- ❌ No StatefulSets
- ❌ No external databases
- ❌ No backup storage

### Default Network Configuration

**On-Premises (NodePort):**
- LDAP: `NODE_IP:30389` (NodePort)
- API: `NODE_IP:30555` (NodePort)
- Internal: `service-name:3893` and `service-name:5555`

**Cloud (LoadBalancer):**
- LDAP: `EXTERNAL_IP:3893` (LoadBalancer)
- API: `EXTERNAL_IP:5555` (LoadBalancer)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `helm lint` and `helm template`
5. Submit a pull request

## CI/CD

This repository includes automated linting for pull requests using the official [helm/chart-testing-action](https://github.com/helm/chart-testing-action):

### Automated Checks

- **Chart Linting**: Validates chart syntax and structure using chart-testing
- **Template Validation**: Ensures all templates render correctly
- **Configuration Validation**: Tests chart with different values files

### Local Testing

Before submitting a pull request, run these commands locally:

```bash
# Lint the chart
helm lint glauth/

# Validate templates
helm template glauth/ > /dev/null
helm template glauth/ -f values-reportportal.yaml > /dev/null

# Test installation (requires kind or minikube)
helm install test-glauth glauth/ --dry-run

# Optional: Bump version to current date (CI/CD does this automatically)
./scripts/bump-version.sh
```

### Workflow Files

- `.github/workflows/lint-chart.yml`: Chart linting workflow using chart-testing-action
- `.github/workflows/release-chart.yml`: Chart release workflow using chart-releaser-action
- `ct.yaml`: Chart testing configuration
- `cr.yaml`: Chart releaser configuration
- `.github/lintconf.yaml`: Lint rules configuration

### Chart Testing Features

The CI/CD pipeline uses [chart-testing](https://github.com/helm/chart-testing) which provides:
- **YAML Linting**: Validates YAML syntax and structure
- **Helm Linting**: Checks chart syntax and best practices
- **Template Validation**: Ensures all templates render correctly

## Releases

This repository automatically releases the Helm chart when changes are merged to the main branch using [helm/chart-releaser-action](https://github.com/helm/chart-releaser-action).

### Automatic Release Process

1. **Version Management**: Chart version automatically updated to current date format `yy.mm.dd` (e.g., `25.01.15` for January 15, 2025)
2. **Trigger**: Release is triggered on push to `main` or `master` branch
3. **Version Bump**: Chart version is automatically bumped to current date
4. **Packaging**: Chart is packaged into `.tgz` files
5. **GitHub Release**: Creates a GitHub release with the chart artifacts
6. **GitHub Pages**: Updates the Helm repository index on GitHub Pages

### Version Management

The chart version follows the date format `yy.mm.dd` and is automatically managed:

```bash
# Manual version bump (optional - CI/CD does this automatically)
./scripts/bump-version.sh

# Example versions:
# 25.01.15 - January 15, 2025
# 25.02.01 - February 1, 2025
# 25.12.31 - December 31, 2025
```

**Note**: The CI/CD pipeline automatically bumps the version to the current date before each release, so manual version bumping is optional.

### Installing the Chart

Once released, you can install the chart using:

```bash
# Add the Helm repository
helm repo add glauth https://your-username.github.io/glauth-helm-chart

# Update repository
helm repo update

# Install the chart
helm install my-glauth glauth/glauth
```

### Release Configuration

- **Chart Directory**: `glauth/`
- **GitHub Pages Branch**: `gh-pages`
- **Release Template**: `{{ .Name }}-{{ .Version }}`
- **Configuration File**: `cr.yaml`

## License

This project is licensed under the same license as GLAuth.

## References

- [GLAuth GitHub Repository](https://github.com/glauth/glauth)
- [GLAuth Documentation](https://github.com/glauth/glauth/wiki)
- [Helm Documentation](https://helm.sh/docs/)