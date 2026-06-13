# ok-rke2 🚀

> **RocketLab** — Launch your OpenKubes cluster in one command.

**OpenKubes-optimized Ansible Role for RKE2 Kubernetes cluster deployment on Hetzner Bare Metal.**

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Ansible Galaxy](https://img.shields.io/badge/ansible--galaxy-kubernauts.ok__rke2-blue)](https://galaxy.ansible.com/kubernauts/ok_rke2)

---

## Overview

`ok-rke2` is a branded, opinionated Ansible Role for deploying [RKE2](https://docs.rke2.io/) Kubernetes clusters on [Hetzner Bare Metal](https://www.hetzner.com/dedicated-rootserver) servers, specifically designed for the [OpenKubes](https://github.com/openkubes/openkubes) platform.

- **Hetzner vSwitch integration** — automatic VLAN Netplan configuration
- **OpenKubes-specific defaults** — KubeVirt-ready sysctl, Multus CNI, MetalLB compatible
- **GPU node support** — NVIDIA taint/label for GPU workers
- **Single-node mode** — removes control-plane taint for all-in-one deployments
- **Security hardening** — SSH, fail2ban out of the box

---

## Requirements

- Ubuntu 24.04 LTS
- Ansible 2.14+
- `ansible.posix` collection: `ansible-galaxy collection install ansible.posix`

---

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `rke2_version` | `v1.33.0+rke2r1` | RKE2 version to install |
| `rke2_type` | `server` | `server` or `agent` |
| `rke2_single_node` | `false` | Remove control-plane taint for single-node |
| `rke2_server_url` | `https://192.168.100.2:9345` | RKE2 server URL (for agents) |
| `rke2_token` | `changeme` | RKE2 cluster token |
| `rke2_tls_san` | `[]` | Additional TLS SANs |
| `rke2_cni` | `calico` | CNI plugin (`calico` or `cilium`) |
| `rke2_cluster_cidr` | `10.42.0.0/16` | Pod CIDR |
| `rke2_service_cidr` | `10.43.0.0/16` | Service CIDR |
| `rke2_disable` | `[rke2-ingress-nginx]` | Components to disable |
| `hetzner_vswitch_enabled` | `true` | Enable vSwitch Netplan config |
| `hetzner_vswitch_interface` | `enp4s0` | Physical network interface |
| `hetzner_vswitch_vlan_id` | `4000` | VLAN ID |
| `hetzner_vswitch_mtu` | `1400` | MTU for VLAN interface |
| `hetzner_vswitch_ip` | `""` | Private IP for this node |
| `hetzner_vswitch_prefix` | `24` | Subnet prefix length |
| `hetzner_vswitch_gateway` | `192.168.100.1` | vSwitch gateway |
| `hetzner_vswitch_routes` | `[192.168.0.0/16]` | Routes via vSwitch gateway |
| `rke2_ssh_hardening` | `true` | Disable SSH password auth |
| `rke2_fail2ban` | `true` | Install and enable fail2ban |
| `rke2_gpu_node` | `false` | Label/taint node as GPU worker |
| `rke2_gpu_taint` | `nvidia.com/gpu=present:NoSchedule` | GPU taint |
| `rke2_gpu_label` | `node-role.kubernetes.io/gpu=true` | GPU label |

---

## Example

### Inventory

```yaml
# inventory/hosts.yml
all:
  children:
    rke2_servers:
      hosts:
        ok-infra:
          ansible_host: 192.168.100.2
          ansible_user: root
    rke2_agents:
      hosts:
        ok-gpu:
          ansible_host: 192.168.100.3
          ansible_user: root
```

### Playbook

```yaml
# playbook.yml
- name: Deploy RKE2 server (ok-infra)
  hosts: rke2_servers
  roles:
    - role: ok-rke2
      vars:
        rke2_type: server
        rke2_single_node: true
        rke2_token: "your-secure-token"
        rke2_tls_san:
          - 192.168.100.2
          - 10.0.0.1
        hetzner_vswitch_interface: enp0s31f6
        hetzner_vswitch_ip: 192.168.100.2

- name: Deploy RKE2 agent (ok-gpu)
  hosts: rke2_agents
  roles:
    - role: ok-rke2
      vars:
        rke2_type: agent
        rke2_token: "your-secure-token"
        rke2_server_url: https://192.168.100.2:9345
        hetzner_vswitch_interface: enp4s0
        hetzner_vswitch_ip: 192.168.100.3
        rke2_gpu_node: true
```

### Run

```bash
# Set the cluster token
export RKE2_TOKEN="your-secure-token"

# Install Ansible dependencies (once)
make requirements

# Test connectivity
make ping

# Deploy full cluster (server + agents)
make install

# Or step by step
make install-server  # Deploy ok-infra first
make install-agent   # Then join ok-gpu
```

All available targets:

```
make help            # Show all available targets
make requirements    # Install Ansible collections
make install         # Deploy full RKE2 cluster
make install-server  # Deploy RKE2 server only (ok-infra)
make install-agent   # Deploy RKE2 agent only (ok-gpu)
make check           # Dry-run — preview changes without applying
make ping            # Test SSH connectivity to all hosts
make lint            # Lint the Ansible role with ansible-lint
make clean           # Remove generated files
```

---

## Hetzner Setup

Before running this role, ensure:

1. Servers are connected to a Hetzner vSwitch
2. vSwitch is connected to a Cloud Network (`192.168.0.0/16`)
3. WireGuard VPN is set up on a Cloud server for access

See [OpenKubes Documentation](https://github.com/openkubes/openkubes) for full setup guide.

---

## Network Architecture

```
Developer (Mac)
      │
   WireGuard VPN
      │
   ok-vpn (Cloud CPX22, public IP)
      │
   Hetzner vSwitch — 192.168.100.0/24
      ├── ok-infra (AX42-U) — 192.168.100.2  ← RKE2 server
      └── ok-gpu (GEX44)    — 192.168.100.3  ← RKE2 agent + GPU
```

---

## License

Apache 2.0 — see [LICENSE](LICENSE)

---

## Part of OpenKubes

This role is part of the [OpenKubes](https://github.com/openkubes/openkubes) platform —
AI-Native Runtime Infrastructure for Sovereign Edge, Industrial Systems and Next-Generation Compute.
