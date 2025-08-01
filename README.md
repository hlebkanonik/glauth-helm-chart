# GLAuth Helm Chart

A production-ready Helm chart for deploying [GLAuth](https://github.com/glauth/glauth) LDAP server on Kubernetes.

## Overview

GLAuth is a secure, fast and memory-efficient LDAP server written in Go. This Helm chart provides an easy way to deploy GLAuth on Kubernetes with:

- **ConfigMap-based configuration**: No need for persistent volumes or external config files
- **Dual port support**: LDAP (3893) and API (5555) ports
- **Ingress support**: Optional ingress configuration for external access
- **Multiple environments**: Pre-configured values for development and production
- **Security features**: Configurable authentication and authorization

## Quick Start

### Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

### Basic Installation

```bash
# Clone the repository
git clone <repository-url>
cd glauth-helm-chart

# Install with default values
helm install my-glauth ./glauth

# Or install with custom values
helm install my-glauth ./glauth -f glauth/values-production.yaml
```

### Development Installation

```bash
# Install with development settings
helm install my-glauth-dev ./glauth -f glauth/values-dev.yaml
```

## Configuration

### Default Configuration

The chart includes a default configuration with:
- LDAP server on port 3893
- API server on port 5555
- Two test users: `tesla` and `einstein` (password: `password`)
- Base DN: `dc=example,dc=com`

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

### Testing LDAP Connection

```bash
# Port forward to access the service
kubectl port-forward svc/my-glauth 3893:3893 5555:5555

# Test LDAP connection
ldapsearch -H ldap://localhost:3893 \
  -D "cn=tesla,dc=example,dc=com" \
  -w password \
  -b "dc=example,dc=com" \
  "(objectClass=*)"
```

### Accessing the API

```bash
# Get version information
curl http://localhost:5555/api/v1/version

# List users
curl http://localhost:5555/api/v1/users
```

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

### Production Deployment

For production deployments, consider:

1. **Enable TLS/SSL**: Set `config.ldaps.enabled: true`
2. **Use strong passwords**: Generate proper SHA256 hashes for user passwords
3. **Restrict API access**: Set `config.api.internals: false`
4. **Configure ingress with TLS**: Use proper certificates
5. **Set resource limits**: Configure appropriate CPU and memory limits

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

The Helm chart creates the following Kubernetes resources:

- **ConfigMap**: Contains the GLAuth configuration file
- **Deployment**: Runs the GLAuth container with the config mounted
- **Service**: Exposes LDAP and API ports
- **Ingress** (optional): Provides external access
- **ServiceAccount**: For pod authentication

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