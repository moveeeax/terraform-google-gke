variable "project_id" {
  description = "ID of the project in which to create the GKE cluster."
  type        = string
}

variable "name" {
  description = "Name of the GKE cluster."
  type        = string
}

variable "location" {
  description = "Region or zone in which to create the cluster."
  type        = string
}

variable "network" {
  description = "Self link or name of the network the cluster runs in."
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Self link or name of the subnetwork the cluster runs in."
  type        = string
  default     = null
}

variable "initial_node_count" {
  description = "Number of nodes created in the default node pool before it is removed."
  type        = number
  default     = 1

  validation {
    condition     = var.initial_node_count >= 1
    error_message = "initial_node_count must be at least 1."
  }
}

variable "remove_default_node_pool" {
  description = "Whether to remove the default node pool after cluster creation."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Whether the cluster is protected from deletion."
  type        = bool
  default     = false
}

variable "release_channel" {
  description = "Release channel for cluster upgrades: UNSPECIFIED, RAPID, REGULAR or STABLE."
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["UNSPECIFIED", "RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "release_channel must be one of UNSPECIFIED, RAPID, REGULAR or STABLE."
  }
}

variable "resource_labels" {
  description = "Labels applied to the cluster."
  type        = map(string)
  default     = {}
}
