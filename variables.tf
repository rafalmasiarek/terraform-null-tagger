variable "context" {
  type        = any
  default     = null
  description = "Bundle of shared settings from a previous call's `context` output. Lets you set namespace/environment/owner/tag_prefix/origin_source/origin_version once in a \"base\" call, then reuse them across many per-resource calls that only need to pass `context` + `name`. Any variable set explicitly below always overrides the matching value in `context`."
  validation {
    condition     = var.context == null ? true : can(keys(var.context))
    error_message = "context must be a map - pass a previous call's `context` output, not a scalar."
  }
}

variable "namespace" {
  type        = string
  default     = null
  description = "Short organization/project identifier, e.g. \"acme\". Required, either here or via context."
}

variable "environment" {
  type        = string
  default     = null
  description = "e.g. dev, staging, prod. Required, either here or via context."
}

variable "name" {
  type        = string
  default     = null
  description = "Base resource name, e.g. \"sre-reports\" - optional, used only for the Name/origin-name tags, and always specific to this one call (never taken from context). Never fed into name_prefix: the module never knows the final, suffixed resource name - that's assembled by the caller via the resource's own native name_prefix/bucket_prefix/identifier_prefix argument."
  validation {
    condition     = var.name == null ? true : length(trimspace(var.name)) > 0
    error_message = "name must be a non-empty string - omit it (null) instead of passing empty or blank."
  }
}

variable "attributes" {
  type        = list(string)
  default     = null
  description = "Extra name_prefix segments, in order (e.g. a region abbreviation like \"euc1\")."
}

variable "delimiter" {
  type    = string
  default = null
}

variable "regex_replace_chars" {
  type        = string
  default     = null
  description = "Terraform regex matching characters to strip from namespace/environment/attributes/name before use. Falls back to context, then to \"/[^a-zA-Z0-9-]/\" (letters, digits, hyphen only)."
}

variable "name_order" {
  type        = list(string)
  default     = null
  description = "Order of name_prefix segments. Valid keys: namespace, environment, attributes."
  validation {
    condition     = var.name_order == null ? true : can(element([for _ in [1] : 1 if length(var.name_order) > 0 && alltrue([for k in var.name_order : k != null && contains(["namespace", "environment", "attributes"], k)])], 0))
    error_message = "name_order must be a non-empty list of: namespace, environment, attributes."
  }
}

variable "tag_prefix" {
  type        = string
  default     = null
  description = "Namespace prefix for tag keys, e.g. \"acme:\". Falls back to context, then to \"tagger:\". Never applied to the \"Name\" tag - AWS reads that key verbatim for the console display name."
}

variable "tag_key_delimiter" {
  type        = string
  default     = null
  description = "Separator used inside composite tag key names (e.g. \"cost<sep>center\", \"db<sep>engine\"). Falls back to context, then to \":\" (a tag tree, e.g. \"tagger:cost:center\"). Set to \"-\" for a flat key instead."
}

variable "owner" {
  type        = string
  default     = null
  description = "Team or person accountable for the resource. Required, either here or via context."
}

variable "owner_contact" {
  type        = string
  default     = null
  description = "Email or @handle (Teams/Slack), e.g. \"sre-team@acme.com\" or \"@sre-team\"."
}

variable "managed_by" {
  type        = bool
  default     = null
  description = "Whether to add the managed-by=terraform tag. Falls back to context, then to true."
}

variable "managed_by_key" {
  type        = string
  default     = null
  description = "Tag key for the managed-by marker - never prefixed with tag_prefix, like Name. Falls back to context, then to \"managed-by\". Override if your org/tooling expects a different casing (e.g. \"ManagedBy\")."
}

variable "cost_center" {
  type    = string
  default = null
}

variable "application" {
  type    = string
  default = null
}

variable "created_at" {
  type        = string
  default     = null
  description = "RFC3339 timestamp, typically time_static.created.rfc3339 in the caller - set once, never changes, to avoid perpetual plan diffs. Always specific to this one call, never taken from context."
}

variable "extra_tags" {
  type        = any
  default     = {}
  description = <<-EOT
    Custom tags, keyed however you like. A scalar value (string, bool,
    number) is used as-is: { security = true } -> security = "true".
    A map value is flattened one level deep, joined with
    tag_key_delimiter: { contact = { email = "a@b.c", phone = "123" } }
    -> contact<delim>email = "a@b.c", contact<delim>phone = "123".
    Null or empty values are dropped.
  EOT
  validation {
    condition = can(element([for _ in [1] : 1 if can(keys(var.extra_tags)) && alltrue([
      for k, v in var.extra_tags : can(keys(v)) ? alltrue([
        for k2, v2 in v : !can(keys(v2)) && !can(flatten(v2))
      ]) : (!can(keys(v)) && !can(flatten(v)))
    ])], 0))
    error_message = "extra_tags must be a map of scalar (string/number/bool) or null values, or maps of scalars one level deep - no lists or deeper nesting."
  }
}

variable "origin_source" {
  type        = string
  default     = null
  description = "Where the calling module came from, e.g. \"github.com/rafalmasiarek/terraform-aws-vpc\". Passive input - this module never detects it itself; pass it from data.tagger_origin.self.source (terraform-provider-tagger) or hardcode it, usually via context so every resource in a stack shares the same value."
}

variable "origin_version" {
  type        = string
  default     = null
  description = "Version/ref of the calling module. Passive input, usually shared via context like origin_source."
}

variable "origin_module" {
  type        = string
  default     = null
  description = "Which sub-module of the origin produced this resource, e.g. \"service\", \"addons\", \"node-group\". Unlike origin_source/origin_version this is NOT shared via context - it's specific to each sub-module and is set per call so a stack built from one origin repo can still show which sub-module created each resource. Null when the caller doesn't track sub-modules (single-module origins)."
}

# Service-category tag data, consolidated into one `any`-typed input
# instead of one variable per category. Adding a new category here never
# requires every consuming module's tagger.tf to gain a new pass-through
# line (see terraform-provider-tagger's tagger.tf export) - the cost is
# per-field type-checking: a typo like `service.databse` silently tags
# nothing instead of erroring. Never pulled from context - always
# specific to this one resource.
#
# Recognized categories, each optional, every field within each optional:
#
#   database = { engine, engine_version, size, multi_az, storage_gb (manual only - RDS storage autoscaling changes it live), storage_type, storage_encrypted }
#   compute  = { instance_id, instance_type, os, os_version, architecture, instance_lifecycle, elastic_ip }
#   cache    = { engine, engine_version, size }
#   load_balancer  = { type, algorithm }
#   object_storage = { storage_class, versioning }
#   block_storage  = { type, file_system_type } - size_gb and iops are deliberately NOT recommended: EBS allows live resize / ModifyVolume performance changes outside Terraform, so tagging them causes perpetual plan diffs (same rule as database.storage_gb and autoscaling_group.desired_capacity)
#   kubernetes     = { version, node_count }
#   serverless     = { runtime, memory_mb, timeout_seconds, architecture }
#   autoscaling_group = { min_size, max_size, desired_capacity (manual only - the autoscaler itself changes it live), launch_template_id, launch_template_version }
#   network = { vpc_id, subnet_id, availability_zone, availability_zone_id, private_ip } - cross-cutting placement info, not tied to one service
#   container  = { cluster, task_family, node_group } - container platform (ECS/EKS); the service name itself goes to the `application` input
variable "service" {
  type        = any
  default     = {}
  description = "Service-category tag data (database, compute, cache, load_balancer, object_storage, block_storage, kubernetes, serverless, autoscaling_group, network, container). See this file's comment above for each category's recognized fields."
  validation {
    condition = var.service == null ? true : can(element([for _ in [1] : 1 if can(keys(var.service)) && alltrue([
      for cat, profile in var.service : profile == null ? true : (can(keys(profile)) ? alltrue([
        for f, v in profile : v == null || (!can(keys(v)) && !can(flatten(v)))
      ]) : false)
    ])], 0))
    error_message = "service must be a map of categories, each a map of scalar (string/number/bool) or null fields - no lists or nested maps."
  }
}
