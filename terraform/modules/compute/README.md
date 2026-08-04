# Compute module

This provider-neutral module defines static compute intent for control-plane
and worker nodes. It creates no resources and configures no provider.

## Contract

`nodes` is keyed by stable logical node identifier. Each entry defines a
hostname, Kubernetes role, CPU, memory, root disk, labels, SSH access intent,
and cloud-init template reference. It may also reserve an availability zone,
GPU profile, and named extra disks for a future provider implementation.

SSH authorized-key and cloud-init values are references and non-secret
parameters only. Secret content must be resolved at deployment time from an
approved secret-management system, never committed to Terraform variables or
state.

`future_autoscaling` reserves policy bounds and optional CPU target without
creating an autoscaler. Static node definitions remain authoritative for the
current dev and prod topologies.

## Validation

The module validates node roles, unique RFC 1123-compatible hostnames, positive
CPU/memory/disk capacity, GPU settings, extra-disk sizes, and autoscaling
bounds. Provider-specific placement, instance types, images, networking,
bootstrap execution, and scaling resources are intentionally deferred.
