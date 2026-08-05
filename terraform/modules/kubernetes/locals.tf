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
    install_containerd    = "${path.module}/scripts/install-containerd.sh"
    prepare_node         = "${path.module}/scripts/prepare-node.sh"
    kubeadm_init         = "${path.module}/scripts/kubeadm-init.sh"
    kubeadm_join         = "${path.module}/scripts/kubeadm-join.sh"
    validate_node        = "${path.module}/scripts/validate-node.sh"
    validate_cluster     = "${path.module}/scripts/validate-cluster.sh"
    configure_kubeconfig = "${path.module}/scripts/configure-kubeconfig.sh"
    validate_control_plane = "${path.module}/scripts/validate-control-plane.sh"
    validate_cni_selection = "${path.module}/scripts/validate-cni-selection.sh"
    reset_worker         = "${path.module}/scripts/reset-worker.sh"
    reset_control_plane  = "${path.module}/scripts/reset-control-plane.sh"
    cloud_init_control_plane = "${path.module}/templates/cloud-init-control-plane.yaml.tftpl"
    cloud_init_worker        = "${path.module}/templates/cloud-init-worker.yaml.tftpl"
    kubeadm_init_config  = "${path.module}/templates/kubeadm-init-config.yaml.tftpl"
    kubeadm_join_config  = "${path.module}/templates/kubeadm-join-config.yaml.tftpl"
    cni_installation_plan = "${path.module}/templates/cni-installation-plan.md.tftpl"
    installation_guide   = "${path.module}/INSTALLATION.md"
  }

  bootstrap_contract = {
    configuration = var.bootstrap_configuration
    assets        = local.bootstrap_asset_paths
  }
}
