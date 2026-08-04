locals {
  bootstrap_asset_paths = {
    containerd_install   = "${path.module}/templates/containerd-install.sh.tftpl"
    node_prerequisites   = "${path.module}/templates/kubernetes-prerequisites.sh.tftpl"
    control_plane_init   = "${path.module}/templates/control-plane-init.sh.tftpl"
    worker_join          = "${path.module}/templates/worker-join.sh.tftpl"
    cluster_health       = "${path.module}/scripts/validate-cluster-health.sh"
    node_readiness       = "${path.module}/scripts/validate-node-readiness.sh"
    control_plane_health = "${path.module}/scripts/validate-control-plane.sh"
    worker_health        = "${path.module}/scripts/validate-workers.sh"
  }

  bootstrap_contract = {
    configuration = var.bootstrap_configuration
    assets        = local.bootstrap_asset_paths
  }
}
