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

# enable_autopilot and initial_node_count are ForceNew. Upgrading the module
# must leave the plan of an existing Standard cluster unchanged.
run "standard_cluster_plan_is_unchanged" {
  assert {
    condition     = google_container_cluster.this.enable_autopilot == null
    error_message = "enable_autopilot must stay unset by default; it is ForceNew."
  }

  assert {
    condition     = google_container_cluster.this.initial_node_count == 1
    error_message = "initial_node_count must still default to 1 on Standard clusters."
  }

  assert {
    condition     = google_container_cluster.this.remove_default_node_pool == true
    error_message = "remove_default_node_pool must still default to true on Standard clusters."
  }
}

run "standard_node_pool_inputs_are_passed_through" {
  variables {
    initial_node_count       = 3
    remove_default_node_pool = false
  }

  assert {
    condition     = google_container_cluster.this.initial_node_count == 3
    error_message = "An explicit initial_node_count must reach the cluster."
  }

  assert {
    condition     = google_container_cluster.this.remove_default_node_pool == false
    error_message = "An explicit remove_default_node_pool = false must reach the cluster."
  }
}

run "autopilot_cluster" {
  variables {
    enable_autopilot    = true
    pods_range_name     = "gke-pods"
    services_range_name = "gke-services"
  }

  assert {
    condition     = google_container_cluster.this.enable_autopilot == true
    error_message = "enable_autopilot = true must reach the cluster."
  }

  assert {
    condition     = google_container_cluster.this.initial_node_count == null && google_container_cluster.this.remove_default_node_pool == null
    error_message = "Node pool arguments must be left unset on Autopilot; the provider rejects remove_default_node_pool there."
  }

  assert {
    condition     = google_container_cluster.this.enable_shielded_nodes == null
    error_message = "enable_shielded_nodes conflicts with enable_autopilot in the provider and must be left unset."
  }

  assert {
    condition     = length(google_container_cluster.this.workload_identity_config) == 0
    error_message = "workload_identity_config must be omitted on Autopilot; GKE binds the workload pool itself and provider 5.x rejects the block."
  }

  assert {
    condition     = google_container_cluster.this.private_cluster_config[0].enable_private_nodes && length(google_container_cluster.this.master_authorized_networks_config) == 1
    error_message = "Private nodes and the authorized networks block must still apply on Autopilot."
  }

  assert {
    condition     = google_container_cluster.this.ip_allocation_policy[0].cluster_secondary_range_name == "gke-pods"
    error_message = "Secondary ranges must still work on Autopilot."
  }
}
