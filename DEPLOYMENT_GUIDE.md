# DPDK TestPMD Helm Chart - Deployment Guide

## Project Structure

```
dpdk-testpmd-bmn-helm/
├── README.md                           # Main project documentation
├── LICENSE                             # Apache 2.0 license
├── .gitignore                          # Git ignore rules
├── DEPLOYMENT_GUIDE.md                 # This file
└── dpdk-testpmd-bmn/                   # Helm chart directory
    ├── Chart.yaml                      # Chart metadata
    ├── values.yaml                     # Default configuration values
    ├── README.md                       # Chart-specific documentation
    ├── .helmignore                     # Helm ignore rules
    └── templates/                      # Kubernetes templates
        ├── _helpers.tpl                # Template helpers
        ├── NOTES.txt                   # Post-installation notes
        ├── serviceaccount.yaml         # Service account template
        ├── configmaps/
        │   └── sriov-device-plugin-config.yaml
        ├── networkattachmentdefinitions/
        │   └── network-attachment-definitions.yaml
        └── pods/
            └── dpdk-pods.yaml          # DPDK pod templates
```

## Security Features Implemented

### 1. Kubernetes Security Standards
- **Service Account**: Dedicated service account with minimal permissions
- **Security Context**: Proper user/group settings and capability management
- **Resource Limits**: CPU, memory, and hugepages limits defined
- **Non-root execution** where possible (DPDK requires root for hardware access)

### 2. Capability Management
- **Minimal Capabilities**: Only required capabilities are granted:
  - `CAP_NET_RAW`: For raw socket operations
  - `NET_ADMIN`: For network administration
  - `SYS_TIME`: For time synchronization
- **Drop All**: All other capabilities are explicitly dropped

### 3. SecComp Profiles
- **Runtime Default**: Uses runtime default SecComp profile for enhanced security

### 4. Network Security
- **VLAN Isolation**: Network traffic is isolated using VLAN tags
- **IP Range Management**: Controlled IP allocation with excluded ranges

## Deployment Prerequisites

### 1. Kubernetes Cluster Requirements
- Kubernetes version 1.20 or higher
- SR-IOV support enabled
- HugePages configured (32GB recommended)

### 2. Required Components
- **SR-IOV Device Plugin**: For SR-IOV device management
- **Multus CNI**: For multi-network support
- **SR-IOV CNI**: For SR-IOV network configuration
- **Whereabouts IPAM**: For IP address management

### 3. Hardware Requirements
- AWS Bare Metal instances (bmn-cx2.metal-48xl or similar)
- Mellanox ConnectX-7 NICs
- Sufficient CPU cores (32+ recommended)
- Large memory (32GB+ per pod)

## Installation Steps

### 1. Prepare the Environment
```bash
# Ensure HugePages are configured
kubectl describe nodes | grep -A 5 hugepages

# Verify SR-IOV devices
kubectl get nodes -o yaml | grep -A 10 allocatable | grep sriov
```

### 2. Install the Chart
```bash
# Basic installation
helm install dpdk-testpmd ./dpdk-testpmd-bmn

# With custom values
helm install dpdk-testpmd ./dpdk-testpmd-bmn \
  --set dpdkPods.nodes[0].hostname=your-node-hostname
```

### 3. Verify Deployment
```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=dpdk-testpmd-bmn

# Check SR-IOV configuration
kubectl get configmap sriovdp-config -n kube-system

# Check network attachments
kubectl get network-attachment-definitions
```

## Testing and Validation

### 1. Run Helm Tests
```bash
helm test dpdk-testpmd
```

### 2. Manual Testing
```bash
# Access a pod
kubectl exec -it mlnx-dpdk-1001-1002-node1-tx -- /bin/bash

# Check network interfaces
ip link show

# Verify SR-IOV devices
lspci | grep Mellanox

# Check HugePages
cat /proc/meminfo | grep Huge
```

### 3. Performance Testing
```bash
# Inside the pod, run DPDK TestPMD
export KUBEPOD_SLICE=$(cut -d: -f3 /proc/self/cgroup)
export CPU=$(cat /sys/fs/cgroup$KUBEPOD_SLICE/cpuset.cpus.effective)
export PCI=$(ethtool -i net1 | grep bus-info | awk '{print $2}')

./build/app/dpdk-testpmd -l ${CPU} -n 6 -a ${PCI} \
  --file-prefix dpdk-test --socket-mem=4096,4096 \
  -- --nb-cores=32 --rxq=24 --txq=24 -i \
  --forward-mode=txonly --txonly-multi-flow
```

## Troubleshooting

### Common Issues and Solutions

1. **Pod Stuck in Pending**
   - **Cause**: Insufficient resources or missing SR-IOV devices
   - **Solution**: Check node resources and SR-IOV device availability

2. **Network Attachment Failures**
   - **Cause**: Missing Multus or SR-IOV CNI
   - **Solution**: Verify CNI installation and configuration

3. **HugePages Allocation Failures**
   - **Cause**: Insufficient HugePages on nodes
   - **Solution**: Configure more HugePages on worker nodes

4. **Permission Denied Errors**
   - **Cause**: Insufficient capabilities or security context issues
   - **Solution**: Review security context and capability settings

### Debug Commands
```bash
# Check SR-IOV device plugin logs
kubectl logs -n kube-system -l app=sriovdp

# Check Multus logs
kubectl logs -n kube-system -l app=multus

# Check pod events
kubectl describe pod <pod-name>

# Check node resources
kubectl describe nodes
```

## Production Considerations

### 1. Resource Planning
- **CPU**: Reserve dedicated cores for DPDK applications
- **Memory**: Allocate sufficient memory and HugePages
- **Network**: Plan VLAN assignments and IP ranges

### 2. Monitoring
- Enable Prometheus monitoring for performance metrics
- Set up alerting for resource utilization
- Monitor network throughput and packet loss

### 3. Security
- Regular security updates for container images
- Network policy enforcement
- Audit logging for privileged operations

### 4. Backup and Recovery
- Backup Helm values and configurations
- Document node-specific configurations
- Plan for disaster recovery scenarios

## Customization

### 1. Values Configuration
Edit `values.yaml` to customize:
- Image repositories and tags
- Resource allocations
- Node assignments
- Network configurations

### 2. Template Modifications
Modify templates in `templates/` directory for:
- Additional security policies
- Custom resource definitions
- Monitoring configurations

### 3. Multi-Environment Support
Create environment-specific values files:
- `values-dev.yaml`
- `values-staging.yaml`
- `values-production.yaml`

## Support and Maintenance

### 1. Updates
- Regular Helm chart updates
- Container image updates
- Kubernetes version compatibility

### 2. Documentation
- Keep documentation up to date
- Document any customizations
- Maintain troubleshooting guides

### 3. Community
- Contribute improvements back to the project
- Report issues and bugs
- Share best practices and use cases
