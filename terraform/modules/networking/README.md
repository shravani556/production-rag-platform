# Networking module

This provider-neutral module defines the networking contract for the RAG
platform. It intentionally creates **no resources** in Phase 6B: no VPC/VNet,
subnet, route table, firewall, load balancer, NAT gateway, VPN, private
endpoint, VM, or Kubernetes resource.

## Inputs

- `network_name` and `cidr` describe the future environment network.
- `dns_settings` preserves DNS resolver, search-domain, hostname, and DNS
  support requirements.
- `future_subnets` reserves named subnet intent, including CIDR, purpose,
  privacy, and optional failure domain.
- `future_load_balancers`, `future_nat`, `future_ingress`, `future_vpn`,
  `future_private_networking`, and `future_storage_endpoints` record future
  integration requirements without selecting a cloud provider.

## Outputs

`network_contract` is a typed description that a future provider-specific
implementation can consume. `network_name` and `cidr` are provided separately
for simple downstream composition.

## Assumptions

- Dev reserves `10.10.0.0/16`; Prod reserves `10.20.0.0/16`. These are
  placeholders only and must be checked against corporate, VPN, and on-premises
  address space before provisioning.
- Future Kubernetes nodes, load balancers, ingress, NAT, VPN, private service
  links, and storage endpoints will use provider-specific child modules.
- Subnet allocation is deliberately deferred until the target provider,
  availability-zone strategy, and service exposure requirements are approved.
