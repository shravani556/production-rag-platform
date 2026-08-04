locals {
  compute_contract = {
    environment        = var.environment
    nodes              = var.nodes
    future_autoscaling = var.future_autoscaling
  }

  nodes_by_role = {
    control_plane = { for key, node in var.nodes : key => node if node.role == "control-plane" }
    workers       = { for key, node in var.nodes : key => node if node.role == "worker" }
  }
}
