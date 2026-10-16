# Changelog

## 0.7.0

### Added
- `origin_module` variable: stamped as `tagger:origin:module` tag, identifies
  which sub-module of one origin repo created a resource. Not inherited from
  context (per-call). Null when unset.

### Changed
- `block_storage` category docs: `size_gb` and `iops` documented as drift
  hazards (EBS ModifyVolume can change them live). Recommend `type` +
  `file_system_type` only. Consistent with `database.storage_gb` and
  `autoscaling_group.desired_capacity` exclusions.
