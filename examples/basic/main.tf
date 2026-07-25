terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 8.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "gke" {
  source = "../.."

  project_id = var.project_id
  name       = "example-cluster"
  location   = var.region

  # Only these ranges can reach the Kubernetes API server. Leaving the list
  # empty would deny all external access, including your own kubectl.
  master_authorized_networks = var.api_access_cidrs

  # Sandbox cluster, so allow terraform destroy to remove it.
  deletion_protection = false

  resource_labels = {
    environment = "sandbox"
  }
}

variable "project_id" {
  description = "Project ID to deploy the example cluster into."
  type        = string
}

variable "region" {
  description = "Region for the google provider and cluster."
  type        = string
  default     = "us-central1"
}

variable "api_access_cidrs" {
  description = "CIDR blocks allowed to reach the cluster's Kubernetes API server."
  type = list(object({
    cidr_block   = string
    display_name = optional(string)
  }))
  default = []
}

output "cluster_name" {
  value = module.gke.name
}
