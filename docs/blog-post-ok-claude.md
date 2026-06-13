# When a 15-Year-Old Disk Died: How an Infrastructure Crisis Became a Platform Strategy

*By Arash Kaffamanesh — OpenKubes / Kubernauts*  
*Written together with Claude by Anthropic*

---

This is not a story about AI.

This is a story about a 15-year-old hard drive, a Kubelet that kept dying, and what happened when an infrastructure crisis met a new way of working.

---

## Part 1: The Incident

It started with a VM that wouldn't boot.

We were provisioning a new node for a Disaster Recovery test. The VirtualMachineInstance stayed stuck in `Scheduling`. No events. No errors. Just silence.

We dug deeper. The Kubelet on our control-plane node was crashing every 5 seconds:

```
level=error msg="Kubelet exited: exit status 1"
```

The kernel told a clearer story:

```
sd 1:0:0:0: [sdb] Sense Key : Medium Error
Unrecovered read error - auto reallocate failed
EXT4-fs error (device dm-0): inode #2631020: comm kubelet: reading directory lblock 0
```

`smartctl` confirmed what we feared:

```
Reallocated_Sector_Ct:   1576   # should be 0
Current_Pending_Sector:   739   # 739 sectors that can no longer be read
Power_On_Hours:        132191   # 15 years of runtime
```

We checked the SSD we thought we could migrate to:

```
231 SSD_Life_Left   FAILING_NOW   1
Power_On_Hours:    110085h        # 12 years
```

Both disks. Simultaneously. At the end of their lives.

We took an emergency ETCD snapshot, secured it, and made the call: the on-premise setup at FirstColo Frankfurt had to go. We needed to move.

---

## Part 2: The Decision

What followed wasn't a planned migration. There was no runbook. No pre-approved architecture. No ticket with acceptance criteria already written.

There was a blank page and a set of constraints:

- ETCD had been running on a single node. That needed to change.
- The Shadow Management Cluster couldn't run on the same hardware as the primary — otherwise DR was theater.
- We needed network isolation without public IPs on bare metal.
- The GPU workload (on-prem AI inference) needed to survive independently.

These decisions happened in conversation. Out loud. In real time.

Within a few hours we had designed:

**The compute layer:** Two Hetzner Bare Metal servers — `ok-infra` (AX42-U, 128GB DDR5, 2TB NVMe) for the Kubernetes control plane and workload VMs, and `ok-gpu` (GEX44, NVIDIA RTX 4000 Ada 20GB) for GPU workloads and AI inference.

**The network layer:** A dedicated WireGuard gateway on a small Cloud VM (`ok-vpn`, CPX22) — completely independent from the Bare Metal nodes. If `ok-infra` fails, the VPN still works. No Bare Metal server has a public IP. Everything goes through WireGuard.

**The DR layer:** The Shadow Management Cluster will eventually run on Proxmox — a completely different hypervisor on completely different hardware. Not on the same KubeVirt infrastructure as the primary. Real independence.

**The exposure layer:** Cloudflare Tunnel for any services that need to be public. No open inbound ports. No public IPs.

Every one of these decisions came with a tradeoff. Every tradeoff was discussed, challenged, and resolved before anything was ordered.

---

## Part 3: The New Workflow

Here is what actually changed.

In the past, a crisis day like this would have produced:
- A few Slack messages
- A rough architecture sketch in someone's notes
- A migration plan that would get written up "later"
- Documentation that would never fully catch up

Instead, this is what happened in parallel with every technical decision:

**Jira stories were created in real time.** Not after. Not the next morning. While we were still deciding whether to use WireGuard or a Hetzner Floating IP, the story was being written — with context, acceptance criteria, architecture notes and links to related tickets.

**Confluence pages were written as we worked.** The WireGuard setup, the server inventory, the netplan configuration, the vSwitch topology — all documented while the terminal was still open.

**A GitHub repository was created and populated within an hour.** An Ansible role (`ok-rke2`) with tasks, templates, handlers, a Makefile, inventory, playbook and full README — not scaffolded and left empty, but written with the actual IP addresses, interface names and configuration from the servers we had just ordered.

**Architecture risks were caught before they became problems.** "What happens if ok-infra goes down and the Shadow Cluster is also on ok-infra?" That question came up in conversation — not in a post-mortem.

The workflow was: think, decide, implement, document — all in one continuous flow. No context switching. No "I'll write this up later." No gap between the decision and the artifact.

---

## Part 4: What Changed

The bottleneck in platform engineering was never coding.

The bottleneck was always translating decisions into artifacts.

A senior engineer makes a hundred small decisions in a crisis day. Most of them never get documented. The ones that do get documented take three times as long to write as they took to make. By the time the runbook is written, the team has already moved on.

What changed here was that the artifact generation happened at the speed of the decision.

Not Claude writing the code. Not AI replacing the engineer. But the friction between "we decided this" and "this is documented, tracked, and committed" — that friction nearly disappeared.

The result:

- 5 Jira stories (OK-32 through OK-36)
- 5 Confluence pages
- 1 GitHub repository with a working Ansible role
- 1 WireGuard VPN running in under 30 minutes
- 2 Bare Metal servers provisioned, networked and accessible via private IP

All in one day. Starting from a Kubelet crash at 3pm.

---

## A Note on AI Collaboration

This wasn't the first time AI played a role in OpenKubes.

Many of the ideas, architectural patterns and documents that shaped OpenKubes over the last 12 months originated in conversations with ChatGPT (by OpenAI). Architecture discussions, code generation, documentation, design decisions, GitOps concepts, edge computing narratives — a large part of what OpenKubes is today was developed through those conversations.

What happened on this particular day was with Claude (by Anthropic) — a different tool, a different style, but the same fundamental shift: AI as an engineering companion, not just a coding assistant.

OpenKubes was shaped through collaboration with both. Different models, different strengths, different moments. And that feels worth saying out loud.

---

## Part 5: What's Next

When `ok-infra` arrives from Hetzner:

```bash
export RKE2_TOKEN="..."
make install
```

And then: KubeVirt, Crossplane, Cluster API, a proper Management Cluster, and eventually a Shadow Cluster on Proxmox with Ceph storage and live VM migration — on hardware that has nothing to do with the primary.

OpenKubes is our effort to build a consistent Kubernetes operating model across local labs, datacenters, edge locations and cloud environments. The Hetzner migration is simply the next step in that journey.

We're building it in the open, one component at a time.

The migration started with a failing disk.

It ended with a clearer vision of what OpenKubes should become.

The `ok-rke2` Ansible role — which we call *RocketLab* internally — is the first published piece:

> **RocketLab — Launch your OpenKubes cluster in one command.**

```bash
make ping   # ✅
make install  # coming soon 🚀
```

---

## Links

- ok-rke2 on GitHub: https://github.com/openkubes/ok-rke2
- OpenKubes: https://github.com/openkubes/openkubes
- Claude by Anthropic: https://claude.ai

---

*Arash Kaffamanesh is the founder of Kubernauts and creator of OpenKubes.*  
*This post was written together with Claude by Anthropic.*
