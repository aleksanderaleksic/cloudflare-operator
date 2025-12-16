# Changelog

All notable changes to the Cloudflare Operator Helm Chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-16

### Added
- Initial Helm chart release for Cloudflare Operator
- Complete Helm chart with all operator components:
  - Custom Resource Definitions (CRDs) for Tunnel, ClusterTunnel, TunnelBinding, and AccessTunnel
  - RBAC resources (ServiceAccount, ClusterRole, ClusterRoleBinding, Role, RoleBinding)
  - Operator deployment with configurable resources and security contexts
  - Webhook server configuration with cert-manager integration
  - Metrics service with Prometheus endpoint
  - Network policies for secure communication
- Comprehensive configuration options through values.yaml
- Feature toggles for webhooks, cert-manager, metrics, RBAC, CRDs, and network policies
- Validation and testing framework:
  - Helm chart linting and validation
  - Template generation testing
  - Version consistency validation
  - Kustomize equivalence validation
  - Comprehensive test suite with Helm test pods
- Documentation:
  - Detailed README with installation and configuration instructions
  - Inline documentation in values.yaml
  - Troubleshooting guide and common issues
  - Usage examples and development guidelines
- Packaging and distribution:
  - Automated chart packaging with validation
  - Package verification and checksums
  - Makefile for development workflows
  - CI/CD integration scripts

### Features
- **Conditional Resource Generation**: Resources are created based on feature flags
- **Security Best Practices**: Non-root containers, read-only filesystems, dropped capabilities
- **Cert-Manager Integration**: Automatic TLS certificate management for webhooks
- **Network Policies**: Optional network isolation for enhanced security
- **Comprehensive Testing**: Multiple validation layers ensure chart reliability
- **Kustomize Compatibility**: Maintains functional equivalence with existing Kustomize deployment

### Configuration
- Supports all operator features with sensible defaults
- Configurable image repository, tag, and pull policy
- Resource limits and requests customization
- Node selector, tolerations, and affinity support
- Webhook and metrics endpoint configuration
- RBAC and security context customization

### Validation
- JSON schema validation for values
- Template validation and linting
- Version consistency checks
- Feature dependency validation
- Comprehensive test coverage

## [Unreleased]

### Planned
- Chart repository publication
- Integration with operator CI/CD pipeline
- Additional configuration options based on user feedback
- Performance optimizations and resource tuning