variable "namespace" {
  type        = string
  description = "Short organization/project identifier, e.g. \"acme\"."
}

variable "environment" {
  type        = string
  description = "e.g. dev, staging, prod"
}

variable "name" {
  type        = string
  default     = null
  description = "Base resource name, e.g. \"sre-reports\" - optional, used only for the Name/origin-name tags. Never fed into name_prefix: the module never knows the final, suffixed resource name - that's assembled by the caller via the resource's own native name_prefix/bucket_prefix/identifier_prefix argument."
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Extra name_prefix segments, in order (e.g. a region abbreviation like \"euc1\")."
}

variable "delimiter" {
  type    = string
  default = "-"
}

variable "name_order" {
  type        = list(string)
  default     = ["namespace", "environment", "attributes"]
  description = "Order of name_prefix segments. Valid keys: namespace, environment, attributes."
}

variable "tag_prefix" {
  type        = string
  default     = ""
  description = "Namespace prefix for tag keys, e.g. \"acme:\". Never applied to the \"Name\" tag - AWS reads that key verbatim for the console display name."
}

variable "owner" {
  type        = string
  description = "Team or person accountable for the resource."
}

variable "owner_contact" {
  type        = string
  default     = null
  description = "Email or @handle (Teams/Slack), e.g. \"sre-team@acme.com\" or \"@sre-team\"."
}

variable "managed_by" {
  type        = bool
  default     = true
  description = "Whether to add managed-by=terraform."
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
  description = "RFC3339 timestamp, typically time_static.created.rfc3339 in the caller - set once, never changes, to avoid perpetual plan diffs."
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}

variable "detect_origin" {
  type        = bool
  default     = false
  description = "Opt-in. Attempts to read the calling module's own source/version from .terraform/modules/modules.json via a local script. Fails soft - a detection failure never breaks plan/apply, it only yields \"unknown\" values."
}
