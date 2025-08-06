# GLAuth Helm Chart

A Helm chart for deploying [GLAuth](https://github.com/glauth/glauth) LDAP server on Kubernetes.

## Introduction

GLAuth is a secure, fast and memory-efficient LDAP server. It's written in Go and provides a simple way to set up an LDAP server for authentication and directory services.

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
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.ldapPort` | LDAP service port | `3893` |
| `service.apiPort` | API service port | `5555` |
| `ingress.enabled` | Enable ingress | `false` |
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

### Accessing LDAP

Once deployed, you can access the LDAP server using:

```bash
# Test LDAP connection
ldapsearch -H ldap://localhost:3893 -D "cn=tesla,dc=example,dc=com" -w password -b "dc=example,dc=com" "(objectClass=*)"
```

### Accessing the API

The GLAuth API is available on port 5555:

```bash
# Get version information
curl http://localhost:5555/api/v1/version
```

### Default Users

The chart includes two default users:
- **tesla** (Password: password)
- **einstein** (Password: password)

### Ingress

To enable ingress, set `ingress.enabled` to `true` and configure your ingress controller:

```yaml
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: glauth.example.com
      paths:
        - path: /
          pathType: Prefix
```

## Security

- The default configuration uses plain LDAP (not LDAPS)
- Passwords are stored as SHA256 hashes
- Consider enabling TLS/SSL for production use
- Review and customize the security settings in the configuration

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=glauth
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=glauth
```

### Port Forward for Testing

```bash
kubectl port-forward svc/my-glauth 3893:3893 5555:5555
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the chart
5. Submit a pull request

## License

This chart is licensed under the same license as GLAuth. 