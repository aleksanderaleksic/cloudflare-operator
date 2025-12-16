# Cloudflare Operator Helm Chart

A Helm chart for deploying the Cloudflare Operator, a Kubernetes operator for managing Cloudflare Argo Tunnels.

## Prerequisites

- Kubernetes 1.20+
- Helm 3.8+
- cert-manager (if webhook functionality is enabled)

## Installation

### Add the Helm Repository

```bash
# Add the repository (when published)
helm repo add cloudflare-operator https://charts.cloudflare-operator.io
helm repo update
```

### Install the Chart

```bash
# Install with default values
helm install cloudflare-operator cloudflare-operator/cloudflare-operator

# Install with custom values
helm install cloudflare-operator cloudflare-operator/cloudflare-operator \
  --set image.tag=v1.0.0 \
  --set features.webhooks.enabled=false
```

### Install from Source

```bash
# Clone the repository
git clone https://github.com/adyanth/cloudflare-operator.git
cd cloudflare-operator

# Install the chart
helm install cloudflare-operator ./charts/cloudflare-operator
```

## Configuration

The following table lists the configurable parameters of the Cloudflare Operator chart and their default values.

### Global Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Override the namespace for all resources | `""` |
| `global.nameOverride` | Override the name of the chart | `""` |
| `global.fullnameOverride` | Override the full name of the chart | `""` |

### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `ghcr.io/adyanth/cloudflare-operator` |
| `image.tag` | Container image tag | `""` (defaults to chart appVersion) |
| `image.pullPolicy` | Container image pull policy | `IfNotPresent` |
| `image.pullSecrets` | Container image pull secrets | `[]` |

### Operator Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `operator.replicas` | Number of operator replicas | `1` |
| `operator.resources.limits.cpu` | CPU limit | `200m` |
| `operator.resources.limits.memory` | Memory limit | `200Mi` |
| `operator.resources.requests.cpu` | CPU request | `100m` |
| `operator.resources.requests.memory` | Memory request | `100Mi` |
| `operator.nodeSelector` | Node selector for operator pods | `{}` |
| `operator.tolerations` | Tolerations for operator pods | `[]` |
| `operator.affinity` | Affinity rules for operator pods | `{}` |
| `operator.terminationGracePeriodSeconds` | Termination grace period | `10` |

### Feature Toggles

| Parameter | Description | Default |
|-----------|-------------|---------|
| `features.webhooks.enabled` | Enable webhook functionality | `true` |
| `features.certManager.enabled` | Enable cert-manager integration | `true` |
| `features.metrics.enabled` | Enable metrics endpoint | `true` |
| `features.rbac.create` | Create RBAC resources | `true` |
| `features.crds.install` | Install Custom Resource Definitions | `true` |
| `features.networkPolicy.enabled` | Enable network policies | `false` |

### Webhook Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `webhook.port` | Webhook server port | `9443` |
| `webhook.certDir` | Certificate directory path | `/tmp/k8s-webhook-server/serving-certs` |
| `webhook.service.type` | Webhook service type | `ClusterIP` |
| `webhook.service.port` | Webhook service port | `443` |
| `webhook.service.targetPort` | Webhook service target port | `9443` |

### Cert-Manager Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `certManager.issuer.create` | Create certificate issuer | `true` |
| `certManager.issuer.name` | Certificate issuer name | `selfsigned-issuer` |
| `certManager.issuer.kind` | Certificate issuer kind | `Issuer` |
| `certManager.certificate.name` | Certificate name | `serving-cert` |
| `certManager.certificate.secretName` | Certificate secret name | `webhook-server-cert` |
| `certManager.certificate.duration` | Certificate duration | `8760h` |
| `certManager.certificate.renewBefore` | Certificate renewal time | `720h` |

### Metrics Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `metrics.service.type` | Metrics service type | `ClusterIP` |
| `metrics.service.port` | Metrics service port | `8443` |
| `metrics.service.targetPort` | Metrics service target port | `8443` |
| `metrics.service.name` | Metrics service port name | `https` |

### RBAC Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rbac.serviceAccountName` | Service account name | `""` (generated) |
| `rbac.serviceAccountAnnotations` | Service account annotations | `{}` |
| `rbac.additionalRules` | Additional RBAC rules | `[]` |

## Usage Examples

### Basic Installation

```bash
helm install cloudflare-operator ./charts/cloudflare-operator
```

### Installation with Custom Image

```bash
helm install cloudflare-operator ./charts/cloudflare-operator \
  --set image.repository=my-registry/cloudflare-operator \
  --set image.tag=v1.2.3
```

### Installation without Webhooks

```bash
helm install cloudflare-operator ./charts/cloudflare-operator \
  --set features.webhooks.enabled=false \
  --set features.certManager.enabled=false
```

### Installation with Network Policies

```bash
helm install cloudflare-operator ./charts/cloudflare-operator \
  --set features.networkPolicy.enabled=true
```

### Installation with Custom Resources

```bash
helm install cloudflare-operator ./charts/cloudflare-operator \
  --set operator.resources.limits.cpu=500m \
  --set operator.resources.limits.memory=512Mi \
  --set operator.replicas=2
```

## Creating Tunnels

After installing the operator, you can create tunnels using Custom Resources:

### Basic Tunnel

```yaml
apiVersion: networking.cfargotunnel.com/v1alpha2
kind: Tunnel
metadata:
  name: example-tunnel
  namespace: default
spec:
  cloudflare:
    email: your-email@example.com
    domain: example.com
    secret: cloudflare-credentials
  newTunnel:
    name: my-tunnel
```

### Cluster Tunnel

```yaml
apiVersion: networking.cfargotunnel.com/v1alpha2
kind: ClusterTunnel
metadata:
  name: cluster-tunnel
spec:
  cloudflare:
    domain: example.com
    secret: cloudflare-credentials
  newTunnel:
    name: cluster-wide-tunnel
```

## Upgrading

### Upgrade the Chart

```bash
helm upgrade cloudflare-operator ./charts/cloudflare-operator
```

### Upgrade with New Values

```bash
helm upgrade cloudflare-operator ./charts/cloudflare-operator \
  --set image.tag=v1.3.0 \
  --reuse-values
```

## Uninstalling

```bash
helm uninstall cloudflare-operator
```

**Note:** This will remove the operator but preserve any Custom Resource instances (tunnels) unless explicitly deleted.

## Troubleshooting

### Common Issues

#### Webhook Certificate Issues

If you encounter webhook certificate issues:

1. Ensure cert-manager is installed and running
2. Check certificate status: `kubectl get certificates -n <namespace>`
3. Verify issuer status: `kubectl get issuers -n <namespace>`

#### RBAC Permission Issues

If the operator lacks permissions:

1. Verify RBAC is enabled: `features.rbac.create=true`
2. Check service account: `kubectl get sa -n <namespace>`
3. Verify cluster role bindings: `kubectl get clusterrolebindings`

#### Pod Startup Issues

If the operator pod fails to start:

1. Check pod logs: `kubectl logs -n <namespace> deployment/cloudflare-operator-controller-manager`
2. Verify image pull secrets if using private registry
3. Check resource limits and node capacity

### Debugging Commands

```bash
# Check operator status
kubectl get pods -n <namespace> -l app.kubernetes.io/name=cloudflare-operator

# View operator logs
kubectl logs -n <namespace> -l app.kubernetes.io/name=cloudflare-operator -f

# Test webhook connectivity
kubectl get validatingadmissionwebhooks
kubectl get mutatingadmissionwebhooks

# Check CRDs
kubectl get crds | grep cfargotunnel

# Run Helm tests
helm test cloudflare-operator
```

## Development

### Testing the Chart

```bash
# Lint the chart
helm lint ./charts/cloudflare-operator

# Template the chart
helm template cloudflare-operator ./charts/cloudflare-operator

# Install and test
helm install cloudflare-operator ./charts/cloudflare-operator
helm test cloudflare-operator
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the chart thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- Documentation: https://github.com/adyanth/cloudflare-operator
- Issues: https://github.com/adyanth/cloudflare-operator/issues
- Discussions: https://github.com/adyanth/cloudflare-operator/discussions