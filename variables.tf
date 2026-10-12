variable "context" {
  type        = any
  default     = null
  description = "Bundle of shared settings from a previous call's `context` output. Lets you set namespace/environment/owner/tag_prefix/origin_source/origin_version once in a \"base\" call, then reuse them across many per-resource calls that only need to pass `context` + `name`. Any variable set explicitly below always overrides the matching value in `context`."
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

variable "name_order" {
  type        = list(string)
  default     = null
  description = "Order of name_prefix segments. Valid keys: namespace, environment, attributes."
}

variable "tag_prefix" {
  type        = string
  default     = null
  description = "Namespace prefix for tag keys, e.g. \"acme:\". Falls back to context, then to \"tagger:\". Never applied to the \"Name\" tag - AWS reads that key verbatim for the console display name."
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
  description = "Whether to add managed-by=terraform. Falls back to context, then to true."
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
  type    = map(string)
  default = {}
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

# Predefined, provider-agnostic service tag sets. Each is optional (default
# null - no tags generated), filled in by hand or by a provider's
# auto-discovery (e.g. terraform-provider-tagger). Never pulled from
# context - always specific to this one resource.

variable "database" {
  type = object({
    engine         = optional(string) # postgres, mysql, mariadb, ...
    engine_version = optional(string)
    size           = optional(string) # db.t3.micro, Standard_B2s, ... - name varies per provider
    multi_az       = optional(bool)
    storage_gb     = optional(number)
  })
  default     = null
  description = "RDS / Azure Database / DO Managed Databases / etc."
}

variable "compute" {
  type = object({
    instance_id   = optional(string)
    instance_type = optional(string) # t3.micro, Standard_B2s, cx11, ...
    os            = optional(string) # ubuntu, amazon-linux, debian, ...
    os_version    = optional(string)
  })
  default     = null
  description = "EC2 / Azure VM / DO Droplet / Hetzner Server / etc."
}

variable "cache" {
  type = object({
    engine         = optional(string) # redis, memcached
    engine_version = optional(string)
    size           = optional(string)
  })
  default     = null
  description = "ElastiCache / Azure Cache for Redis / DO Managed Redis / etc."
}

variable "load_balancer" {
  type = object({
    type      = optional(string) # application, network, classic
    algorithm = optional(string) # round_robin, least_connections, ...
  })
  default     = null
  description = "ALB/NLB / Azure Load Balancer / DO LB / Hetzner Load Balancer / etc."
}

variable "object_storage" {
  type = object({
    storage_class = optional(string) # standard, infrequent_access, glacier, ...
    versioning    = optional(bool)
  })
  default     = null
  description = "S3 / Azure Blob / DO Spaces / Hetzner Object Storage / etc."
}

variable "block_storage" {
  type = object({
    size_gb = optional(number)
    type    = optional(string) # ssd, hdd, gp3, io2, ...
    iops    = optional(number)
  })
  default     = null
  description = "EBS / Azure Disk / DO Volumes / Hetzner Volumes / etc."
}

variable "kubernetes" {
  type = object({
    version    = optional(string)
    node_count = optional(number)
  })
  default     = null
  description = "EKS / AKS / DOKS / etc. Null on providers without a managed offering (e.g. Hetzner, where k3s is typically self-managed on compute instances instead)."
}

variable "serverless" {
  type = object({
    runtime         = optional(string) # nodejs20.x, python3.12, ...
    memory_mb       = optional(number)
    timeout_seconds = optional(number)
  })
  default     = null
  description = "Lambda / Azure Functions / Cloudflare Workers / etc."
}
