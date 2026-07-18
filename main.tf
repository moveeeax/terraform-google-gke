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

  release_channel {
    channel = var.release_channel
  }
}
