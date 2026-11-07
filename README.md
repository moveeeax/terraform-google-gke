# terraform-google-gke

Terraform module that manages a [Google Cloud](https://cloud.google.com/)
Google Kubernetes Engine cluster (`google_container_cluster`). It creates a
cluster with the default node pool removed so node pools can be managed
separately.

## Security defaults

The module ships a locked-down baseline. Every item below is a default you can
relax, not a default you have to remember to turn on:

- **The control plane is not reachable from the internet.** GKE leaves the
  public API server endpoint open to `0.0.0.0/0` when
  `master_authorized_networks_config` is absent, so the module always emits the
  block. An empty `master_authorized_networks` list authorizes nothing — set it
  to the ranges that actually need `kubectl`.
- **Nodes have no public IP addresses** (`enable_private_nodes = true`). Give
  the subnetwork Cloud NAT or Private Google Access for outbound traffic.
- **Workload Identity is bound to `<project_id>.svc.id.goog`.** Without it every
  pod can reach the node's service account through the metadata server.
- **Legacy ABAC is off and Shielded Nodes are on**, pinned explicitly so a
  provider default change cannot flip them.
- **`deletion_protection` defaults to `true`**, matching the provider.

## Usage

```hcl
module "gke" {
  source = "github.com/moveeeax/terraform-google-gke?ref=v1.0.0"

  project_id      = var.project_id
  name            = "prod-cluster"
  location        = "us-central1"
  network         = module.vpc.self_link
  subnetwork      = module.subnet.self_link
  release_channel = "REGULAR"

  # VPC-native, with Pod and Service IPs from the subnetwork's own secondary
  # ranges, and Dataplane V2.
  pods_range_name     = "gke-pods"
  services_range_name = "gke-services"
  datapath_provider   = "ADVANCED_DATAPATH"

  master_authorized_networks = [
    {
      cidr_block   = "203.0.113.0/24"
      display_name = "office"
    },
    {
      cidr_block   = "198.51.100.0/28"
      display_name = "ci-runners"
    },
  ]
}
```

## Networking: secondary ranges and Dataplane V2

`pods_range_name` and `services_range_name` name two secondary ranges that
must already exist on `subnetwork`. Set both and the module emits an
`ip_allocation_policy` with them and pins `networking_mode = "VPC_NATIVE"`, so
Pod and Service addresses come from ranges you planned with the VPC rather than
ones GKE picks. In a Shared VPC the ranges live on the host project's subnet.
Setting only one of the two fails at plan time.

`datapath_provider = "ADVANCED_DATAPATH"` turns on GKE Dataplane V2, which
enforces Kubernetes NetworkPolicy without a separate Calico add-on.
`LEGACY_DATAPATH` is the iptables/kube-proxy datapath.

All three settings are ForceNew in the google provider. Their defaults are
`null`, so the module adds nothing to clusters created by earlier versions and
their plans stay empty. Setting them on an existing cluster whose current value
differs replaces the cluster, which `deletion_protection = true` stops at
apply time. Set them when creating a cluster, and use `ADVANCED_DATAPATH` for
new clusters.

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version        |
|-----------|----------------|
| terraform | >= 1.5         |
| google    | >= 5.0, < 9.0  |

The test suite under [`tests/`](tests) additionally needs Terraform >= 1.7 for
`mock_provider`.

## Inputs

| Name                         | Description                                                                    | Type                                                        | Default     | Required |
|------------------------------|--------------------------------------------------------------------------------|-------------------------------------------------------------|-------------|:--------:|
| `project_id`                 | ID of the project in which to create the cluster.                              | `string`                                                    | n/a         |   yes    |
| `name`                       | Name of the GKE cluster. Must be RFC 1035: lowercase, <= 40 characters.        | `string`                                                    | n/a         |   yes    |
| `location`                   | Region or zone in which to create the cluster.                                 | `string`                                                    | n/a         |   yes    |
| `network`                    | Self link or name of the network.                                              | `string`                                                    | `"default"` |    no    |
| `subnetwork`                 | Self link or name of the subnetwork.                                           | `string`                                                    | `null`      |    no    |
| `pods_range_name`            | Subnetwork secondary range for Pod IPs. Set with `services_range_name`. ForceNew. | `string`                                                 | `null`      |    no    |
| `services_range_name`        | Subnetwork secondary range for Service IPs. Set with `pods_range_name`. ForceNew. | `string`                                                 | `null`      |    no    |
| `datapath_provider`          | `ADVANCED_DATAPATH` (Dataplane V2) or `LEGACY_DATAPATH`. Null leaves GKE's default. ForceNew. | `string`                                     | `null`      |    no    |
| `initial_node_count`         | Nodes in the default node pool before removal.                                 | `number`                                                    | `1`         |    no    |
| `remove_default_node_pool`   | Whether to remove the default node pool.                                       | `bool`                                                      | `true`      |    no    |
| `deletion_protection`        | Whether the cluster is protected from deletion.                                | `bool`                                                      | `true`      |    no    |
| `release_channel`            | Release channel for cluster upgrades.                                          | `string`                                                    | `"REGULAR"` |    no    |
| `master_authorized_networks` | CIDR blocks allowed to reach the API server. Empty denies all external access. | `list(object({ cidr_block = string, display_name = optional(string) }))` | `[]` | no |
| `enable_private_nodes`       | Whether nodes get only RFC 1918 addresses instead of public IPs.               | `bool`                                                      | `true`      |    no    |
| `enable_private_endpoint`    | Whether the control plane is reachable only on its private endpoint.           | `bool`                                                      | `false`     |    no    |
| `master_ipv4_cidr_block`     | RFC 1918 /28 range for the hosted control plane.                               | `string`                                                    | `null`      |    no    |
| `enable_workload_identity`   | Whether to bind the cluster to the project's workload identity pool.           | `bool`                                                      | `true`      |    no    |
| `resource_labels`            | Labels applied to the cluster.                                                 | `map(string)`                                               | `{}`        |    no    |

## Outputs

| Name        | Description                              |
|-------------|------------------------------------------|
| `id`        | Identifier of the GKE cluster.           |
| `name`      | Name of the GKE cluster.                 |
| `endpoint`  | IP address of the Kubernetes API server. |
| `self_link` | URI of the GKE cluster.                  |

## Testing

```sh
terraform init -backend=false
terraform test
```

The suite runs against `mock_provider "google"`, so it needs no credentials and
no network access.

## License

[MIT](LICENSE)
