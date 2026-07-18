terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
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

output "cluster_name" {
  value = module.gke.name
}
