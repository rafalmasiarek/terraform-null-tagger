output "name_prefix" {
  description = "namespace-environment-attributes-, ready to concatenate with the caller's own resource name."
  value       = local.name_prefix
}

output "computed_name" {
  description = "name_prefix + var.name, without any AWS-generated suffix. Null if var.name was not given."
  value       = local.computed_name
}

output "tags" {
  description = "Full tag map, including Name (unprefixed) and every other tag key under tag_prefix."
  value       = local.tags
}

output "tags_by_name" {
  description = "Batch mode: one entry per key in var.names, each a full tag map (including its own Name/origin-name). Use when tagging many resources from a single module call instead of one call per resource."
  value       = local.tags_by_name
}

output "computed_name_by_name" {
  description = "Batch mode: one entry per key in var.names, each name_prefix + that entry's name, without any AWS-generated suffix."
  value       = local.computed_name_by_name
}

output "context" {
  description = "Bundle of every shared, stack-wide setting (namespace, environment, owner, tag_prefix, origin_source, origin_version, ...) from this call - pass straight into a later call's `context` input to avoid repeating them per resource."
  value       = local.context
}
