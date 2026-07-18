output "id" {
  description = "Identifier of the GKE cluster."
  value       = google_container_cluster.this.id
}

output "name" {
  description = "Name of the GKE cluster."
  value       = google_container_cluster.this.name
}

output "endpoint" {
  description = "IP address of the cluster's Kubernetes API server."
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "self_link" {
  description = "URI of the GKE cluster."
  value       = google_container_cluster.this.self_link
}
