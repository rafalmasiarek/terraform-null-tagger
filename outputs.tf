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

output "context" {
  description = "Bundle of every shared, stack-wide setting (namespace, environment, owner, tag_prefix, origin_source, origin_version, ...) from this call - pass straight into a later call's `context` input to avoid repeating them per resource."
  value       = local.context
}
