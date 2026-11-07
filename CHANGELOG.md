# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/). Releases up to v1.1.0 predate this
file; see the [GitHub releases](https://github.com/moveeeax/terraform-google-gke/releases).

## [Unreleased]

### Added

- `pods_range_name` and `services_range_name` inputs. Set together, they add an
  `ip_allocation_policy` that takes Pod and Service IPs from named secondary
  ranges of the subnetwork and pin `networking_mode = "VPC_NATIVE"`. Setting
  only one fails at plan time.
- `datapath_provider` input. `ADVANCED_DATAPATH` enables GKE Dataplane V2.
- All three default to `null`, so clusters created by earlier versions see no
  diff. They are ForceNew: setting them on an existing cluster whose value
  differs replaces the cluster.

[Unreleased]: https://github.com/moveeeax/terraform-google-gke/compare/v1.1.0...HEAD
