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

  # Dataplane V2. Only settable at creation: changing it later replaces the
  # cluster.
  datapath_provider = "ADVANCED_DATAPATH"

  # Optional named secondary ranges on the subnetwork, set as a pair. Null on
  # both lets GKE allocate the ranges.
  subnetwork          = var.subnetwork
  pods_range_name     = var.pods_range_name
  services_range_name = var.services_range_name

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

variable "subnetwork" {
  description = "Subnetwork the cluster runs in. Must carry the secondary ranges named below when they are set."
  type        = string
  default     = null
}

variable "pods_range_name" {
  description = "Secondary range on the subnetwork for Pod IPs."
  type        = string
  default     = null
}

variable "services_range_name" {
  description = "Secondary range on the subnetwork for Service IPs."
  type        = string
  default     = null
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
