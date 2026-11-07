variable "project_id" {
  description = "ID of the project in which to create the GKE cluster."
  type        = string
}

variable "name" {
  description = "Name of the GKE cluster."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]{0,38}[a-z0-9])?$", var.name))
    error_message = "name must start with a lowercase letter, contain only lowercase letters, digits and hyphens, not end with a hyphen, and be at most 40 characters."
  }
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

variable "pods_range_name" {
  description = "Name of the subnetwork secondary range used for Pod IPs. Set together with services_range_name to make the cluster VPC-native with explicitly planned ranges, which Shared VPC setups need. Null (the default) adds no ip_allocation_policy. ForceNew: setting or changing it on an existing cluster replaces the cluster."
  type        = string
  default     = null

  validation {
    condition     = var.pods_range_name == null || can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", var.pods_range_name))
    error_message = "pods_range_name must be a secondary range name: lowercase letters, digits and hyphens, starting with a letter, at most 63 characters."
  }
}

variable "services_range_name" {
  description = "Name of the subnetwork secondary range used for Service ClusterIPs. Set together with pods_range_name. ForceNew: setting or changing it on an existing cluster replaces the cluster."
  type        = string
  default     = null

  validation {
    condition     = var.services_range_name == null || can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", var.services_range_name))
    error_message = "services_range_name must be a secondary range name: lowercase letters, digits and hyphens, starting with a letter, at most 63 characters."
  }
}

variable "datapath_provider" {
  description = "Datapath provider: ADVANCED_DATAPATH enables GKE Dataplane V2 (eBPF, with built-in Kubernetes NetworkPolicy enforcement), LEGACY_DATAPATH is the iptables kube-proxy datapath. Null (the default) leaves it to GKE, which uses the legacy datapath. Use ADVANCED_DATAPATH for new clusters. ForceNew: changing it on an existing cluster replaces the cluster."
  type        = string
  default     = null

  validation {
    condition     = var.datapath_provider == null || contains(["ADVANCED_DATAPATH", "LEGACY_DATAPATH"], var.datapath_provider)
    error_message = "datapath_provider must be ADVANCED_DATAPATH, LEGACY_DATAPATH or null."
  }
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
  description = "Whether the cluster is protected from deletion. Matches the provider default; set it to false only for throwaway clusters."
  type        = bool
  default     = true
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

variable "master_authorized_networks" {
  description = <<-EOT
    CIDR blocks allowed to reach the cluster's Kubernetes API server. The
    master_authorized_networks_config block is always emitted, so the default
    empty list denies all external access to the control plane. Add the
    operator and CI ranges that need kubectl access.
  EOT
  type = list(object({
    cidr_block   = string
    display_name = optional(string)
  }))
  default = []

  validation {
    condition     = alltrue([for n in var.master_authorized_networks : can(cidrhost(n.cidr_block, 0))])
    error_message = "Every master_authorized_networks entry needs a valid CIDR block, for example \"203.0.113.0/24\"."
  }
}

variable "enable_private_nodes" {
  description = "Whether nodes get only RFC 1918 addresses instead of public IPs. Private nodes need Cloud NAT or Private Google Access for outbound traffic."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Whether the control plane is reachable only on its private endpoint. Requires enable_private_nodes and network connectivity from the client."
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_private_endpoint || var.enable_private_nodes
    error_message = "enable_private_endpoint requires enable_private_nodes to be true."
  }
}

variable "master_ipv4_cidr_block" {
  description = "RFC 1918 /28 range for the hosted control plane. Leave null to let GKE pick one."
  type        = string
  default     = null

  validation {
    condition     = var.master_ipv4_cidr_block == null || can(cidrhost(var.master_ipv4_cidr_block, 0))
    error_message = "master_ipv4_cidr_block must be a valid CIDR block, for example \"172.16.0.0/28\"."
  }
}

variable "enable_workload_identity" {
  description = "Whether to bind the cluster to the project's workload identity pool so pods use their own identity instead of the node service account."
  type        = bool
  default     = true
}

variable "resource_labels" {
  description = "Labels applied to the cluster."
  type        = map(string)
  default     = {}
}
