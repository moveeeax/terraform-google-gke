locals {
  # Secondary ranges are passed as a pair; the precondition on the cluster
  # rejects setting only one of them.
  use_secondary_ranges = var.pods_range_name != null && var.services_range_name != null
}

resource "google_container_cluster" "this" {
  project    = var.project_id
  name       = var.name
  location   = var.location
  network    = var.network
  subnetwork = var.subnetwork

  initial_node_count       = var.initial_node_count
  remove_default_node_pool = var.remove_default_node_pool
  deletion_protection      = var.deletion_protection
  resource_labels          = var.resource_labels

  # Both match the current provider defaults. Pinning them means a future
  # provider release cannot quietly flip them, and the test suite can assert
  # on them.
  enable_legacy_abac    = false
  enable_shielded_nodes = true

  # Both are ForceNew. Null leaves the provider and GKE defaults in place, so an
  # existing cluster sees no diff; setting either on a running cluster whose
  # value differs replaces it.
  datapath_provider = var.datapath_provider
  networking_mode   = local.use_secondary_ranges ? "VPC_NATIVE" : null

  # Pod and Service IPs come from named secondary ranges of the subnetwork, so
  # the ranges are planned with the VPC (and visible to a Shared VPC host)
  # instead of GKE carving its own. Omitted when no ranges are given, which
  # keeps existing clusters unchanged: ip_allocation_policy is ForceNew.
  dynamic "ip_allocation_policy" {
    for_each = local.use_secondary_ranges ? [1] : []
    content {
      cluster_secondary_range_name  = var.pods_range_name
      services_secondary_range_name = var.services_range_name
    }
  }

  release_channel {
    channel = var.release_channel
  }

  # Always emitted. When this block is absent GKE leaves the public control
  # plane endpoint reachable from 0.0.0.0/0, so an empty
  # master_authorized_networks list denies all external access to the
  # Kubernetes API server instead of silently allowing the whole internet.
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Without a workload pool every pod can reach the node's service account
  # through the metadata server and inherits all of its permissions.
  dynamic "workload_identity_config" {
    for_each = var.enable_workload_identity ? [1] : []
    content {
      workload_pool = "${var.project_id}.svc.id.goog"
    }
  }

  lifecycle {
    precondition {
      condition     = (var.pods_range_name == null) == (var.services_range_name == null)
      error_message = "pods_range_name and services_range_name must be set together: both name secondary ranges of the cluster's subnetwork."
    }
  }
}
