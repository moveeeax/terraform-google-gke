# Requires Terraform >= 1.7 for mock_provider. The module itself still only
# needs >= 1.5; this constraint applies to running the test suite.
mock_provider "google" {}

variables {
  project_id = "example-project"
  name       = "example-cluster"
  location   = "us-central1"
}

run "control_plane_denies_the_internet_by_default" {
  assert {
    condition     = length(google_container_cluster.this.master_authorized_networks_config) == 1
    error_message = "master_authorized_networks_config must always be emitted, otherwise the Kubernetes API server stays reachable from 0.0.0.0/0."
  }

  assert {
    condition     = length(google_container_cluster.this.master_authorized_networks_config[0].cidr_blocks) == 0
    error_message = "With no master_authorized_networks configured the cluster must not authorize any external CIDR block."
  }
}

run "nodes_are_private_by_default" {
  assert {
    condition     = google_container_cluster.this.private_cluster_config[0].enable_private_nodes
    error_message = "Nodes must not get public IP addresses by default."
  }
}

run "workload_identity_is_enabled_by_default" {
  assert {
    condition     = length(google_container_cluster.this.workload_identity_config) == 1
    error_message = "Workload Identity must be configured by default, otherwise pods inherit the node service account."
  }

  assert {
    condition     = google_container_cluster.this.workload_identity_config[0].workload_pool == "example-project.svc.id.goog"
    error_message = "The workload pool must be derived from the cluster's project."
  }
}

run "cluster_is_protected_from_deletion_by_default" {
  assert {
    condition     = google_container_cluster.this.deletion_protection
    error_message = "deletion_protection must default to true so an accidental destroy does not take the cluster with it."
  }
}

run "legacy_abac_stays_disabled" {
  assert {
    condition     = google_container_cluster.this.enable_legacy_abac == false
    error_message = "Legacy ABAC must stay disabled."
  }
}

run "shielded_nodes_stay_enabled" {
  assert {
    condition     = google_container_cluster.this.enable_shielded_nodes
    error_message = "Shielded nodes must stay enabled."
  }
}

run "authorized_networks_are_propagated" {
  variables {
    master_authorized_networks = [
      {
        cidr_block   = "203.0.113.0/24"
        display_name = "office"
      },
      {
        cidr_block = "198.51.100.7/32"
      },
    ]
  }

  assert {
    condition     = length(google_container_cluster.this.master_authorized_networks_config[0].cidr_blocks) == 2
    error_message = "Both authorized networks should reach the cluster resource."
  }

  assert {
    condition = toset([
      for b in google_container_cluster.this.master_authorized_networks_config[0].cidr_blocks : b.cidr_block
    ]) == toset(["203.0.113.0/24", "198.51.100.7/32"])
    error_message = "The configured CIDR blocks should be passed through unchanged."
  }
}

run "workload_identity_can_be_disabled" {
  variables {
    enable_workload_identity = false
  }

  assert {
    condition     = length(google_container_cluster.this.workload_identity_config) == 0
    error_message = "enable_workload_identity = false must drop the workload_identity_config block."
  }
}

run "secondary_ranges_make_the_cluster_vpc_native" {
  variables {
    pods_range_name     = "gke-pods"
    services_range_name = "gke-services"
  }

  assert {
    condition     = google_container_cluster.this.ip_allocation_policy[0].cluster_secondary_range_name == "gke-pods"
    error_message = "pods_range_name must reach ip_allocation_policy.cluster_secondary_range_name."
  }

  assert {
    condition     = google_container_cluster.this.ip_allocation_policy[0].services_secondary_range_name == "gke-services"
    error_message = "services_range_name must reach ip_allocation_policy.services_secondary_range_name."
  }

  assert {
    condition     = google_container_cluster.this.networking_mode == "VPC_NATIVE"
    error_message = "Named secondary ranges only work on a VPC-native cluster."
  }
}

run "dataplane_v2_can_be_enabled" {
  variables {
    pods_range_name     = "gke-pods"
    services_range_name = "gke-services"
    datapath_provider   = "ADVANCED_DATAPATH"
  }

  assert {
    condition     = google_container_cluster.this.datapath_provider == "ADVANCED_DATAPATH"
    error_message = "datapath_provider must be passed through to the cluster."
  }
}
