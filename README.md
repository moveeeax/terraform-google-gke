# terraform-google-gke

Terraform module that manages a [Google Cloud](https://cloud.google.com/)
Google Kubernetes Engine cluster (`google_container_cluster`). It creates a
cluster with the default node pool removed so node pools can be managed
separately.

## Usage

```hcl
module "gke" {
  source = "github.com/cybercapybara/terraform-google-gke"

  project_id      = var.project_id
  name            = "prod-cluster"
  location        = "us-central1"
  network         = module.vpc.self_link
  subnetwork      = module.subnet.self_link
  release_channel = "REGULAR"
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| google    | >= 5.0   |

## Inputs

| Name                       | Description                                                    | Type          | Default      | Required |
|----------------------------|----------------------------------------------------------------|---------------|--------------|:--------:|
| `project_id`               | ID of the project in which to create the cluster.              | `string`      | n/a          |   yes    |
| `name`                     | Name of the GKE cluster.                                       | `string`      | n/a          |   yes    |
| `location`                 | Region or zone in which to create the cluster.                 | `string`      | n/a          |   yes    |
| `network`                  | Self link or name of the network.                              | `string`      | `"default"`  |    no    |
| `subnetwork`               | Self link or name of the subnetwork.                           | `string`      | `null`       |    no    |
| `initial_node_count`       | Nodes in the default node pool before removal.                 | `number`      | `1`          |    no    |
| `remove_default_node_pool` | Whether to remove the default node pool.                       | `bool`        | `true`       |    no    |
| `deletion_protection`      | Whether the cluster is protected from deletion.                | `bool`        | `false`      |    no    |
| `release_channel`          | Release channel for cluster upgrades.                          | `string`      | `"REGULAR"`  |    no    |
| `resource_labels`          | Labels applied to the cluster.                                 | `map(string)` | `{}`         |    no    |

## Outputs

| Name        | Description                                          |
|-------------|------------------------------------------------------|
| `id`        | Identifier of the GKE cluster.                      |
| `name`      | Name of the GKE cluster.                            |
| `endpoint`  | IP address of the Kubernetes API server.            |
| `self_link` | URI of the GKE cluster.                             |

## License

[MIT](LICENSE)
