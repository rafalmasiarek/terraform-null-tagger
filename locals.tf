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
  managed_by_key = coalesce(var.managed_by_key, try(var.context.managed_by_key, null), "managed-by")
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
      namespace      = local.namespace
      environment    = local.environment
      owner          = local.owner
      tagger-version = local.tagger_module_version
    },
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

  # Predefined, provider-agnostic service tag sets (database, compute,
  # cache, load_balancer, object_storage, block_storage, kubernetes) -
  # each optional, flattened into "<service>-<field>" keys (underscores
  # become hyphens to match every other tag key's style), skipping any
  # service left null and any field left null within a given service.
  service_profiles = {
    db         = var.database
    compute    = var.compute
    cache      = var.cache
    lb         = var.load_balancer
    objstore   = var.object_storage
    volume     = var.block_storage
    k8s        = var.kubernetes
    serverless = var.serverless
  }

  service_tags = merge([
    for service, profile in local.service_profiles : profile == null ? {} : {
      for field, value in profile : "${service}-${replace(field, "_", "-")}" => tostring(value)
      if value != null
    }
  ]...)

  prefixed_tags = {
    for k, v in merge(local.standard_tags, local.origin_tags, local.service_tags, var.extra_tags) :
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
    namespace      = local.namespace
    environment    = local.environment
    owner          = local.owner
    delimiter      = local.delimiter
    tag_prefix     = local.tag_prefix
    name_order     = local.name_order
    managed_by     = local.managed_by
    managed_by_key = local.managed_by_key
    owner_contact  = local.owner_contact
    cost_center    = local.cost_center
    application    = local.application
    origin_source  = local.origin_source
    origin_version = local.origin_version
  }
}
