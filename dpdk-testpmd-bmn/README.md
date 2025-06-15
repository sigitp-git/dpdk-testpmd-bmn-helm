# DPDK TestPMD on AWS Bare Metal Nodes Helm Chart

This Helm chart deploys DPDK TestPMD applications on AWS Bare Metal Nodes with SR-IOV networking support.

## Prerequisites

- Kubernetes cluster with SR-IOV support
- AWS Bare Metal instances with Mellanox ConnectX-7 NICs
- SR-IOV Device Plugin installed
- Multus CNI installed
- Whereabouts IPAM installed
- HugePages configured on worker nodes

## Installation

### Basic Installation

```bash
helm install dpdk-testpmd ./dpdk-testpmd-bmn
```

### Custom Configuration

```bash
helm install dpdk-testpmd ./dpdk-testpmd-bmn \
  --set dpdkPods.image.tag=latest \
  --set dpdkPods.nodes[0].hostname=your-node-hostname
```

## Configuration

### Key Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageRegistry` | Container image registry | `291615555612.dkr.ecr.us-east-1.amazonaws.com` |
| `dpdkPods.image.repository` | DPDK container image repository | `sigitp-ecr` |
| `dpdkPods.image.tag` | DPDK container image tag | `ubuntu-mlnx-dpdk-amd64` |
| `dpdkPods.resources.requests.cpu` | CPU request per pod | `33` |
| `dpdkPods.resources.requests.memory` | Memory request per pod | `32Gi` |
| `dpdkPods.resources.requests.hugepages-1Gi` | HugePages request | `8Gi` |

## Usage

### Accessing DPDK Pods

```bash
# List all DPDK pods
kubectl get pods -l app.kubernetes.io/name=dpdk-testpmd-bmn

# Access a TX pod
kubectl exec -it mlnx-dpdk-1001-1002-node1-tx -- /bin/bash

# Access an RX pod
kubectl exec -it mlnx-dpdk-1001-1002-node1-rx -- /bin/bash
```

## Testing

Run the included tests:

```bash
helm test dpdk-testpmd
```

## Upgrading

```bash
helm upgrade dpdk-testpmd ./dpdk-testpmd-bmn
```

## Uninstalling

```bash
helm uninstall dpdk-testpmd
```
