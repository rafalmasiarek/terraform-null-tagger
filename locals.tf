locals {
  # Precedence for every shared (stack-wide) setting: explicit variable on
  # this call > context from a previous call > hardcoded default. name,
  # attributes and created_at are deliberately NOT pulled from context -
  # they're always specific to this one call. try() against var.context
  # directly (not an intermediate local defaulting to {}) because a
  # ternary's two branches would need an identical object type, which {}
  # never has against an arbitrary `any`-typed context.
  namespace      = coalesce(var.namespace, try(var.context.namespace, null))
  environment    = coalesce(var.environment, try(var.context.environment, null))
  owner          = coalesce(var.owner, try(var.context.owner, null))
  delimiter      = coalesce(var.delimiter, try(var.context.delimiter, null), "-")
  tag_prefix     = coalesce(var.tag_prefix, try(var.context.tag_prefix, null), "tagger:")
  name_order     = var.name_order != null ? var.name_order : try(var.context.name_order, ["namespace", "environment", "attributes"])
  managed_by     = var.managed_by != null ? var.managed_by : try(var.context.managed_by, true)
  owner_contact  = var.owner_contact != null ? var.owner_contact : try(var.context.owner_contact, null)
  cost_center    = var.cost_center != null ? var.cost_center : try(var.context.cost_center, null)
  application    = var.application != null ? var.application : try(var.context.application, null)
  origin_source  = var.origin_source != null ? var.origin_source : try(var.context.origin_source, null)
  origin_version = var.origin_version != null ? var.origin_version : try(var.context.origin_version, null)

  attributes = coalesce(var.attributes, [])

  # name_prefix: namespace/environment/attributes only - never the specific
  # resource name. The caller appends its own bare name and relies on the
  # target resource's native name_prefix/bucket_prefix/identifier_prefix
  # argument for the AWS-generated uniqueness suffix.
  name_segments_map = {
    namespace   = local.namespace
    environment = local.environment
    attributes  = join(local.delimiter, local.attributes)
  }

  name_segments_ordered = [
    for key in local.name_order : local.name_segments_map[key]
    if local.name_segments_map[key] != ""
  ]

  name_prefix = "${lower(join(local.delimiter, local.name_segments_ordered))}${local.delimiter}"

  # Only meaningful when var.name is given - the predicted full name (prefix
  # + bare name), without any AWS-generated suffix, used purely for the
  # human-readable Name tag.
  computed_name = var.name != null ? "${local.name_prefix}${var.name}" : null

  standard_tags = merge(
    {
      namespace   = local.namespace
      environment = local.environment
      owner       = local.owner
    },
    local.managed_by ? { managed-by = "terraform" } : {},
    local.owner_contact != null ? { owner-contact = local.owner_contact } : {},
    local.cost_center != null ? { cost-center = local.cost_center } : {},
    local.application != null ? { application = local.application } : {},
    var.created_at != null ? { created-at = var.created_at } : {},
    var.name != null ? { origin-name = var.name } : {},
  )

  origin_tags = merge(
    local.origin_source != null ? { origin = local.origin_source } : {},
    local.origin_version != null ? { version = local.origin_version } : {},
  )

  prefixed_tags = {
    for k, v in merge(local.standard_tags, local.origin_tags, var.extra_tags) :
    "${local.tag_prefix}${k}" => v
  }

  # Name is special-cased: AWS Console reads this exact key, verbatim, for
  # the resource's display name - it must never carry tag_prefix.
  tags = var.name != null ? merge(local.prefixed_tags, { Name = local.computed_name }) : local.prefixed_tags

  # Batch mode: one module call, many resource names. prefixed_tags is
  # already name-independent (namespace/environment/owner/origin/... are
  # the same for every entry) - only Name and origin-name vary per key.
  tags_by_name = {
    for key, name in var.names : key => merge(
      local.prefixed_tags,
      { "${local.tag_prefix}origin-name" = name },
      { Name = "${local.name_prefix}${name}" },
    )
  }

  computed_name_by_name = {
    for key, name in var.names : key => "${local.name_prefix}${name}"
  }

  # Bundle of every shared (non-per-call) setting, for the NEXT call's
  # `context` input - deliberately excludes name/attributes/created_at.
  context = {
    namespace      = local.namespace
    environment    = local.environment
    owner          = local.owner
    delimiter      = local.delimiter
    tag_prefix     = local.tag_prefix
    name_order     = local.name_order
    managed_by     = local.managed_by
    owner_contact  = local.owner_contact
    cost_center    = local.cost_center
    application    = local.application
    origin_source  = local.origin_source
    origin_version = local.origin_version
  }
}
