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
