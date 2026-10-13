locals {
  # Precedence for every shared (stack-wide) setting: explicit variable on
  # this call > context from a previous call > hardcoded default. name,
  # attributes and created_at are deliberately NOT pulled from context -
  # they're always specific to this one call. try() against var.context
  # directly (not an intermediate local defaulting to {}) because a
  # ternary's two branches would need an identical object type, which {}
  # never has against an arbitrary `any`-typed context.
  regex_replace_chars = coalesce(var.regex_replace_chars, try(var.context.regex_replace_chars, null), "/[^a-zA-Z0-9-]/")

  # Raw values - used as-is for tag values, so a caller's original casing
  # (e.g. "Acme") is never altered in the tags output.
  namespace         = coalesce(var.namespace, try(var.context.namespace, null))
  environment       = coalesce(var.environment, try(var.context.environment, null))
  owner             = coalesce(var.owner, try(var.context.owner, null))
  delimiter         = coalesce(var.delimiter, try(var.context.delimiter, null), "-")
  tag_prefix        = coalesce(var.tag_prefix, try(var.context.tag_prefix, null), "tagger:")
  tag_key_delimiter = coalesce(var.tag_key_delimiter, try(var.context.tag_key_delimiter, null), ":")
  name_order        = var.name_order != null ? var.name_order : try(var.context.name_order, ["namespace", "environment", "attributes"])
  managed_by        = var.managed_by != null ? var.managed_by : try(var.context.managed_by, true)
  managed_by_key    = coalesce(var.managed_by_key, try(var.context.managed_by_key, null), "managed-by")
  owner_contact     = var.owner_contact != null ? var.owner_contact : try(var.context.owner_contact, null)
  cost_center       = var.cost_center != null ? var.cost_center : try(var.context.cost_center, null)
  application       = var.application != null ? var.application : try(var.context.application, null)
  origin_source     = var.origin_source != null ? var.origin_source : try(var.context.origin_source, null)
  origin_version    = var.origin_version != null ? var.origin_version : try(var.context.origin_version, null)

  attributes = coalesce(var.attributes, [])

  # Sanitized + lowercased - name_prefix only, never a tag value. A stray
  # space or symbol in namespace/environment/attributes would otherwise
  # produce an invalid resource name downstream.
  namespace_for_prefix   = local.namespace != null ? lower(replace(local.namespace, local.regex_replace_chars, "")) : null
  environment_for_prefix = local.environment != null ? lower(replace(local.environment, local.regex_replace_chars, "")) : null
  attributes_for_prefix  = [for a in local.attributes : lower(replace(a, local.regex_replace_chars, ""))]

  # name_prefix: namespace/environment/attributes only - never the specific
  # resource name. The caller appends its own bare name and relies on the
  # target resource's native name_prefix/bucket_prefix/identifier_prefix
  # argument for the AWS-generated uniqueness suffix.
  name_segments_map = {
    namespace   = local.namespace_for_prefix
    environment = local.environment_for_prefix
    attributes  = join(local.delimiter, local.attributes_for_prefix)
  }

  name_segments_ordered = [
    for key in local.name_order : local.name_segments_map[key]
    if local.name_segments_map[key] != ""
  ]

  name_prefix = "${lower(join(local.delimiter, local.name_segments_ordered))}${local.delimiter}"

  # Only meaningful when var.name is given - the predicted full name (prefix
  # + bare name), without any AWS-generated suffix, used purely for the
  # human-readable Name tag. var.name itself is never sanitized, same as
  # the origin-name tag below - only name_prefix is.
  computed_name = var.name != null ? "${local.name_prefix}${var.name}" : null

  standard_tags = merge(
    {
      namespace   = local.namespace
      environment = local.environment
      owner       = local.owner
    },
    local.owner_contact != null ? { "owner${local.tag_key_delimiter}contact" = local.owner_contact } : {},
    local.cost_center != null ? { "cost${local.tag_key_delimiter}center" = local.cost_center } : {},
    local.application != null ? { application = local.application } : {},
    var.created_at != null ? { "created${local.tag_key_delimiter}at" = var.created_at } : {},
    var.name != null ? { "origin${local.tag_key_delimiter}name" = var.name } : {},
  )

  origin_tags = merge(
    local.origin_source != null ? { origin = local.origin_source } : {},
    local.origin_version != null ? { version = local.origin_version } : {},
  )

  # Predefined, provider-agnostic service tag sets (database, compute,
  # cache, load_balancer, object_storage, block_storage, kubernetes,
  # serverless, autoscaling_group) - each optional, flattened into
  # "<service><tag_key_delimiter><field>" keys, skipping any service left
  # null and any field left null within a given service.
  service_profiles = {
    db         = try(var.service.database, null)
    compute    = try(var.service.compute, null)
    cache      = try(var.service.cache, null)
    lb         = try(var.service.load_balancer, null)
    objstore   = try(var.service.object_storage, null)
    volume     = try(var.service.block_storage, null)
    k8s        = try(var.service.kubernetes, null)
    serverless = try(var.service.serverless, null)
    asg        = try(var.service.autoscaling_group, null)
    net        = try(var.service.network, null)
  }

  # tag_key_delimiter groups by category/service only
  # (asg:launch-template-version) - a multi-word field name stays one
  # hyphenated slug, never exploded into its own tree levels.
  service_tags = merge([
    for service, profile in local.service_profiles : profile == null ? {} : {
      for field, value in profile : "${service}${local.tag_key_delimiter}${replace(field, "_", "-")}" => tostring(value)
      if value != null && tostring(value) != ""
    }
  ]...)

  # extra_tags values are either a scalar (used as-is under its own key) or
  # a map (flattened one level deep, joined with tag_key_delimiter).
  # can(keys(v)) is how we tell the two apart - it succeeds for any
  # map/object, fails (caught by can()) for a string/bool/number.
  extra_tags_flat = merge([
    for k, v in var.extra_tags : can(keys(v)) ? {
      for k2, v2 in v : "${k}${local.tag_key_delimiter}${k2}" => tostring(v2)
    } : { "${k}" = tostring(v) }
  ]...)

  prefixed_tags = {
    for k, v in merge(local.standard_tags, local.origin_tags, local.service_tags, local.extra_tags_flat) :
    "${local.tag_prefix}${k}" => v
  }

  # Name and managed-by are special-cased, never prefixed: AWS Console reads
  # Name verbatim for the display name, and managed-by is a cross-tool
  # convention (automation/cleanup scripts, policies) that external tools
  # expect to find under its own bare key, not namespaced.
  managed_by_tag = local.managed_by ? { (local.managed_by_key) = "terraform" } : {}

  tags = merge(
    local.prefixed_tags,
    local.managed_by_tag,
    var.name != null ? { Name = local.computed_name } : {},
  )

  # Bundle of every shared (non-per-call) setting, for the NEXT call's
  # `context` input - deliberately excludes name/attributes/created_at.
  context = {
    namespace           = local.namespace
    environment         = local.environment
    owner               = local.owner
    delimiter           = local.delimiter
    regex_replace_chars = local.regex_replace_chars
    tag_prefix          = local.tag_prefix
    tag_key_delimiter   = local.tag_key_delimiter
    name_order          = local.name_order
    managed_by          = local.managed_by
    managed_by_key      = local.managed_by_key
    owner_contact       = local.owner_contact
    cost_center         = local.cost_center
    application         = local.application
    origin_source       = local.origin_source
    origin_version      = local.origin_version
  }
}
