# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/). Releases up to v1.1.0 predate this
file; see the [GitHub releases](https://github.com/moveeeax/terraform-google-gke/releases).

## [Unreleased]

## [1.3.0] - 2026-11-08

### Added

- `enable_autopilot` input (default `false`) to create a GKE Autopilot cluster.
  It is ForceNew and null when off, so existing clusters see no diff. With
  Autopilot on, the module leaves `initial_node_count`,
  `remove_default_node_pool`, `enable_shielded_nodes` and
  `workload_identity_config` unset, and rejects at plan time
  `initial_node_count`, `remove_default_node_pool`,
  `enable_workload_identity = false` and `release_channel = "UNSPECIFIED"`.
- `examples/autopilot`.

### Changed

- `initial_node_count` and `remove_default_node_pool` now default to `null`
  instead of `1` and `true`. On Standard clusters null still resolves to `1`
  and `true`, so plans do not change; the null default lets the module tell an
  explicit value apart on Autopilot.

## [1.2.0] - 2026-11-07

### Added

- `pods_range_name` and `services_range_name` inputs. Set together, they add an
  `ip_allocation_policy` that takes Pod and Service IPs from named secondary
  ranges of the subnetwork and pin `networking_mode = "VPC_NATIVE"`. Setting
  only one fails at plan time.
- `datapath_provider` input. `ADVANCED_DATAPATH` enables GKE Dataplane V2.
- All three default to `null`, so clusters created by earlier versions see no
  diff. They are ForceNew: setting them on an existing cluster whose value
  differs replaces the cluster.

[Unreleased]: https://github.com/moveeeax/terraform-google-gke/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/moveeeax/terraform-google-gke/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/moveeeax/terraform-google-gke/compare/v1.1.0...v1.2.0
