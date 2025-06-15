# DPDK TestPMD on AWS Bare Metal Nodes - Helm Chart

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Helm](https://img.shields.io/badge/Helm-v3-blue.svg)](https://helm.sh/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20+-blue.svg)](https://kubernetes.io/)

A production-ready Helm chart for deploying DPDK TestPMD applications on AWS Bare Metal Nodes with SR-IOV networking support.

## Overview

This Helm chart provides a complete solution for deploying high-performance DPDK TestPMD applications on AWS Bare Metal instances with Mellanox ConnectX-7 NICs. It includes:

- **SR-IOV Device Plugin Configuration**: Automatic configuration for Mellanox ConnectX-7 NICs
- **Network Attachment Definitions**: Multi-network support with VLAN isolation
- **Security Best Practices**: Kubernetes security standards compliance
- **Production Ready**: Comprehensive monitoring and observability support
- **Multi-Node Support**: Deploy across multiple bare metal nodes

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Bare Metal Node                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │   TX Pod        │  │   RX Pod        │                      │
│  │                 │  │                 │                      │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │                      │
│  │ │ DPDK TestPMD│ │  │ │ DPDK TestPMD│ │                      │
│  │ │ Application │ │  │ │ Application │ │                      │
│  │ └─────────────┘ │  │ └─────────────┘ │                      │
│  └─────────────────┘  └─────────────────┘                      │
│           │                     │                              │
│  ┌─────────────────────────────────────────────────────────────┤
│  │              SR-IOV Virtual Functions                       │
│  └─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────┤
│  │            Mellanox ConnectX-7 NICs                        │
│  │  PF1: 0000:05:00.0  PF2: 0000:05:00.1                     │
│  │  PF3: 0001:05:00.0  PF4: 0001:05:00.1                     │
│  └─────────────────────────────────────────────────────────────┤
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

1. **Kubernetes Cluster**: Version 1.20 or higher
2. **AWS Bare Metal Instances**: With Mellanox ConnectX-7 NICs
3. **SR-IOV Support**: Device plugin and CNI installed
4. **Multus CNI**: For multi-network support
5. **Whereabouts IPAM**: For IP address management
6. **HugePages**: Configured on worker nodes (32GB recommended)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-org/dpdk-testpmd-bmn-helm.git
   cd dpdk-testpmd-bmn-helm
   ```

2. **Install the chart**:
   ```bash
   helm install dpdk-testpmd ./dpdk-testpmd-bmn
   ```

3. **Verify the deployment**:
   ```bash
   kubectl get pods -l app.kubernetes.io/name=dpdk-testpmd-bmn
   ```

### Configuration

The chart can be customized using values. Key parameters:

```yaml
# values.yaml
global:
  imageRegistry: "291615555612.dkr.ecr.us-east-1.amazonaws.com"

dpdkPods:
  image:
    repository: "sigitp-ecr"
    tag: "ubuntu-mlnx-dpdk-amd64"
  
  nodes:
    - name: "node1"
      hostname: "your-node-hostname"
      pods:
        tx:
          enabled: true
          resources:
            requests:
              cpu: "33"
              memory: "32Gi"
              hugepages-1Gi: "8Gi"
        rx:
          enabled: true
          resources:
            requests:
              cpu: "33"
              memory: "32Gi"
              hugepages-1Gi: "8Gi"
```

## Features

### Security

- **Minimal Privileges**: Only required capabilities are granted
- **Security Contexts**: Proper user/group settings
- **Service Account**: Dedicated service account with minimal permissions
- **SecComp Profiles**: Enhanced security with runtime default profiles

### Networking

- **SR-IOV Support**: Full SR-IOV configuration for Mellanox ConnectX-7
- **Multi-Network**: Support for multiple network interfaces per pod
- **VLAN Isolation**: Network isolation using VLAN tags
- **IP Management**: Automatic IP allocation using Whereabouts IPAM

### Performance

- **HugePages**: 1GB HugePages support for optimal memory performance
- **CPU Pinning**: Dedicated CPU cores for DPDK applications
- **NUMA Awareness**: NUMA-optimized resource allocation

### Monitoring

- **Prometheus Integration**: Optional Prometheus metrics collection
- **Health Checks**: Comprehensive health monitoring
- **Resource Monitoring**: CPU, memory, and network utilization tracking

## Usage Examples

### Basic Deployment

```bash
helm install my-dpdk ./dpdk-testpmd-bmn
```

### Custom Node Configuration

```bash
helm install my-dpdk ./dpdk-testpmd-bmn \
  --set dpdkPods.nodes[0].hostname=ip-10-0-58-16.ec2.internal \
  --set dpdkPods.image.tag=latest
```

### Production Deployment

```bash
helm install my-dpdk ./dpdk-testpmd-bmn \
  -f values-production.yaml \
  --set monitoring.enabled=true
```

### Running DPDK TestPMD

1. **Access a pod**:
   ```bash
   kubectl exec -it mlnx-dpdk-1001-1002-node1-tx -- /bin/bash
   ```

2. **Set environment variables**:
   ```bash
   export KUBEPOD_SLICE=$(cut -d: -f3 /proc/self/cgroup)
   export CPU=$(cat /sys/fs/cgroup$KUBEPOD_SLICE/cpuset.cpus.effective)
   export PCI=$(ethtool -i net1 | grep bus-info | awk '{print $2}')
   ```

3. **Run TestPMD**:
   ```bash
   ./build/app/dpdk-testpmd -l ${CPU} -n 6 -a ${PCI} \
     --file-prefix dpdk-test --socket-mem=4096,4096 \
     -- --nb-cores=32 --rxq=24 --txq=24 -i \
     --forward-mode=txonly --txonly-multi-flow
   ```

## Testing

Run the included test suite:

```bash
helm test my-dpdk
```

The tests verify:
- SR-IOV ConfigMap creation
- Network Attachment Definitions
- Pod deployment and readiness
- Resource allocation

## Troubleshooting

### Common Issues

1. **Pods stuck in Pending**:
   - Check node resources: `kubectl describe nodes`
   - Verify SR-IOV devices: `kubectl get nodes -o yaml | grep -A 10 allocatable`

2. **Network attachment failures**:
   - Check Multus installation: `kubectl get pods -n kube-system | grep multus`
   - Verify SR-IOV CNI: `kubectl get pods -n kube-system | grep sriov`

3. **HugePages allocation failures**:
   - Check HugePages on nodes: `kubectl describe nodes | grep -A 5 hugepages`
   - Verify kernel configuration

### Debug Commands

```bash
# Check SR-IOV device plugin logs
kubectl logs -n kube-system -l app=sriovdp

# Check pod events
kubectl describe pod <pod-name>

# Verify network attachments
kubectl get network-attachment-definitions

# Check resource allocation
kubectl top pods
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Development

```bash
# Lint the chart
helm lint dpdk-testpmd-bmn

# Test template rendering
helm template test-release dpdk-testpmd-bmn --debug

# Package the chart
helm package dpdk-testpmd-bmn
```

## Changelog

### v0.1.0 (Initial Release)
- SR-IOV support for Mellanox ConnectX-7
- Multi-node deployment capability
- Security best practices implementation
- Comprehensive documentation
- Production-ready configuration

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/your-org/dpdk-testpmd-bmn-helm/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/dpdk-testpmd-bmn-helm/discussions)
- **Documentation**: [Wiki](https://github.com/your-org/dpdk-testpmd-bmn-helm/wiki)

## Acknowledgments

- [DPDK Project](https://www.dpdk.org/) for the high-performance packet processing framework
- [SR-IOV Network Device Plugin](https://github.com/k8snetworkplumbingwg/sriov-network-device-plugin) for SR-IOV support
- [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni) for multi-network support
- [Whereabouts](https://github.com/k8snetworkplumbingwg/whereabouts) for IP address management
