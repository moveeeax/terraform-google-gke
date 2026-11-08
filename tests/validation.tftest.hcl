# Requires Terraform >= 1.7 for mock_provider. These runs prove that bad input
# is rejected at plan time instead of failing part-way through an apply.
mock_provider "google" {}

variables {
  project_id = "example-project"
  name       = "example-cluster"
  location   = "us-central1"
}

run "rejects_invalid_release_channel" {
  command = plan

  variables {
    release_channel = "Regular"
  }

  expect_failures = [var.release_channel]
}

run "rejects_invalid_cluster_name" {
  command = plan

  variables {
    name = "Example_Cluster"
  }

  expect_failures = [var.name]
}

run "rejects_overlong_cluster_name" {
  command = plan

  variables {
    name = "aaaaaaaaaa-bbbbbbbbbb-cccccccccc-dddddddddd"
  }

  expect_failures = [var.name]
}

run "rejects_malformed_authorized_network" {
  command = plan

  variables {
    master_authorized_networks = [
      {
        cidr_block = "203.0.113.0"
      },
    ]
  }

  expect_failures = [var.master_authorized_networks]
}

run "rejects_malformed_master_cidr" {
  command = plan

  variables {
    master_ipv4_cidr_block = "172.16.0.0"
  }

  expect_failures = [var.master_ipv4_cidr_block]
}

run "rejects_private_endpoint_without_private_nodes" {
  command = plan

  variables {
    enable_private_nodes    = false
    enable_private_endpoint = true
  }

  expect_failures = [var.enable_private_endpoint]
}

run "rejects_zero_initial_node_count" {
  command = plan

  variables {
    initial_node_count = 0
  }

  expect_failures = [var.initial_node_count]
}

run "rejects_pods_range_without_services_range" {
  command = plan

  variables {
    pods_range_name = "gke-pods"
  }

  expect_failures = [google_container_cluster.this]
}

run "rejects_services_range_without_pods_range" {
  command = plan

  variables {
    services_range_name = "gke-services"
  }

  expect_failures = [google_container_cluster.this]
}

run "rejects_malformed_range_name" {
  command = plan

  variables {
    pods_range_name     = "GKE_Pods"
    services_range_name = "gke-services"
  }

  expect_failures = [var.pods_range_name]
}

run "rejects_unknown_datapath_provider" {
  command = plan

  variables {
    datapath_provider = "DATAPLANE_V2"
  }

  expect_failures = [var.datapath_provider]
}

run "rejects_initial_node_count_on_autopilot" {
  command = plan

  variables {
    enable_autopilot   = true
    initial_node_count = 1
  }

  expect_failures = [google_container_cluster.this]
}

run "rejects_remove_default_node_pool_on_autopilot" {
  command = plan

  variables {
    enable_autopilot         = true
    remove_default_node_pool = true
  }

  expect_failures = [google_container_cluster.this]
}

run "rejects_disabled_workload_identity_on_autopilot" {
  command = plan

  variables {
    enable_autopilot         = true
    enable_workload_identity = false
  }

  expect_failures = [google_container_cluster.this]
}

run "rejects_unspecified_release_channel_on_autopilot" {
  command = plan

  variables {
    enable_autopilot = true
    release_channel  = "UNSPECIFIED"
  }

  expect_failures = [google_container_cluster.this]
}
