# GLAuth Helm Chart

A lightweight Helm chart for deploying [GLAuth](https://github.com/glauth/glauth) LDAP server on Kubernetes.

## Overview

**⚠️ CRUCIAL: This is a lightweight Helm chart designed for testing purposes only.**

GLAuth is a secure, fast and memory-efficient LDAP server written in Go. This Helm chart provides an easy way to deploy GLAuth on Kubernetes with:

- **Lightweight design**: Optimized for testing and development environments
- **ConfigMap-based configuration**: No need for persistent volumes or external databases
- **No persistent storage**: All configuration stored in ConfigMap, no PVC required
- **No external dependencies**: Self-contained without database requirements
- **Dual port support**: LDAP (3893) and API (5555) ports
- **Date-based versioning**: Uses `yy.mm.dd` format for easy tracking

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

## Configuration

### Default Configuration

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

## CI/CD

This repository includes automated linting and releases:

### Automated Checks

- **Chart Linting**: Validates chart syntax and structure using chart-testing
- **Template Validation**: Ensures all templates render correctly
- **Configuration Validation**: Tests chart with different values files

### Workflow Files

- `.github/workflows/lint-chart.yml`: Chart linting workflow using chart-testing-action
- `.github/workflows/release-chart.yml`: Chart release workflow using chart-releaser-action
- `ct.yaml`: Chart testing configuration
- `cr.yaml`: Chart releaser configuration
- `.github/lintconf.yaml`: Lint rules configuration

## Releases

This repository automatically releases the Helm chart when changes are merged to the main branch using [helm/chart-releaser-action](https://github.com/helm/chart-releaser-action).

### Automatic Release Process

1. **Version Management**: Chart version automatically updated to current date format `yy.mm.dd` (e.g., `25.01.15` for January 15, 2025)
2. **Trigger**: Release is triggered on push to `main` or `master` branch
3. **Version Bump**: Chart version is automatically bumped to current date
4. **Packaging**: Chart is packaged into `.tgz` files
5. **GitHub Release**: Creates a GitHub release with the chart artifacts
6. **GitHub Pages**: Updates the Helm repository index on GitHub Pages

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

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `helm lint` and `helm template`
5. Submit a pull request

## License

This project is licensed under the same license as GLAuth.

## References

- [GLAuth GitHub Repository](https://github.com/glauth/glauth)
- [GLAuth Documentation](https://github.com/glauth/glauth/wiki)
- [Helm Documentation](https://helm.sh/docs/)