# Requires Terraform >= 1.7 for mock_provider. Kept in its own file because the
# marker defaults below must not apply to runs that set these attributes: the
# mock provider refuses to override configured values.
#
# Computed attributes the module may leave unset get a marker value from the
# mock. Seeing the marker in the result proves the module did not set the
# attribute itself.
mock_provider "google" {
  mock_resource "google_container_cluster" {
    defaults = {
      datapath_provider = "unset-by-module"
      networking_mode   = "unset-by-module"
    }
  }
}

variables {
  project_id = "example-project"
  name       = "example-cluster"
  location   = "us-central1"
}

# ip_allocation_policy, networking_mode and datapath_provider are all ForceNew.
# Emitting any of them by default would replace clusters created by earlier
# versions of the module.
run "networking_is_left_to_gke_by_default" {
  assert {
    condition     = length(google_container_cluster.this.ip_allocation_policy) == 0
    error_message = "No ip_allocation_policy may be emitted unless secondary ranges are given; it is ForceNew."
  }

  assert {
    condition     = google_container_cluster.this.datapath_provider == "unset-by-module"
    error_message = "datapath_provider must stay unset by default; it is ForceNew."
  }

  assert {
    condition     = google_container_cluster.this.networking_mode == "unset-by-module"
    error_message = "networking_mode must stay unset by default; it is ForceNew."
  }
}
